#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define dsDEBUG 0
#if dsDEBUG
#  define dsWARN(msg)  warn(msg)
#else
#  define dsWARN(msg)
#endif


/*

Upgrade strings to utf8

*/
bool _utf8_set(SV* sv, HV* seen, int onoff) {
  I32 i;
  HV* myHash;
  HE* HEntry;
  SV** AValue;
  
redo_utf8:
  if (SvROK(sv)) {
    if (has_seen(sv, seen))
      return TRUE;
    sv = SvRV(sv);
    goto redo_utf8;
  }

  switch (SvTYPE(sv)) {

    case SVt_PV:
    case SVt_PVNV: {
      dsWARN("string (PV)\n");
      dsWARN(SvUTF8(sv) ? "UTF8 is on\n" : "UTF8 is off\n");
      if (onoff && ! SvUTF8(sv)) {
        sv_utf8_upgrade(sv);
      } else if (! onoff && SvUTF8(sv)) {
        sv_utf8_downgrade(sv, 0);
      }
      break;
    }
    case SVt_PVAV: {
      dsWARN("Found array\n");
      for(i = 0; i <= av_len((AV*) sv); i++) {
        AValue = av_fetch((AV*) sv, i, 0);
        _utf8_set(*AValue, seen, onoff);
      }
      break;
    }
    case SVt_PVHV: {
      dsWARN("Found hash\n");
      myHash = (HV*) sv;
      hv_iterinit(myHash);
      while( HEntry = hv_iternext(myHash) ) {
        _utf8_set(HeVAL(HEntry), seen, onoff);
      }
      break;
    }
  }
  return TRUE;
}


/*

Returns true if sv contains a utf8 string

*/
bool _has_utf8(SV* sv, HV* seen) {
  I32 i;
  SV** AValue;
  HV* myHash;
  HE* HEntry;

redo_has_utf8:
  if (SvROK(sv)) {
    if (has_seen(sv, seen))
      return FALSE;
    sv = SvRV(sv);
    goto redo_has_utf8;
  }

  switch (SvTYPE(sv)) {

    case SVt_PV:
    case SVt_PVNV: {
      dsWARN("string (PV)\n");
      dsWARN(SvUTF8(sv) ? "UTF8 is on\n" : "UTF8 is off\n");
      if (SvUTF8(sv)) {
        dsWARN("Has UTF8\n");
        return TRUE;
      }
      break;
    }
    case SVt_PVAV: {
      dsWARN("Found array\n");
      for(i = 0; i <= av_len((AV*) sv); i++) {
        AValue = av_fetch((AV*) sv, i, 0);
        if (_has_utf8(*AValue, seen))
          return TRUE;
      }
      break;
    }
    case SVt_PVHV: {
      dsWARN("Found hash\n");
      myHash = (HV*) sv;
      hv_iterinit(myHash);
      while( HEntry = hv_iternext(myHash) ) {
        if (_has_utf8(HeVAL(HEntry), seen))
          return TRUE;
      }
      break;
    }
  }
  return FALSE;
}


/*

unbless a any object within the data structure

*/
SV* _unbless(SV* sv, HV* seen) {
  I32 i;
  SV** AValue;
  HV* myHash;
  HE* HEntry;

redo_unbless:
  if (SvROK(sv)) {
    
    if (has_seen(sv, seen))
      return sv;

    if (sv_isobject(sv)) {
      sv = (SV*)SvRV(sv);
      SvOBJECT_off(sv);
    } else {
      sv = (SV*) SvRV(sv);
    }
    goto redo_unbless;
  }

  switch (SvTYPE(sv)) {

    case SVt_PVAV: {
      dsWARN("an array\n");
      for(i = 0; i <= av_len((AV*) sv); i++) {
        AValue = av_fetch((AV*) sv, i, 0);
        _unbless(*AValue, seen);
      }
      break;
    }
    case SVt_PVHV: {
      dsWARN("a hash (PVHV)\n");
      myHash = (HV*) sv;
      hv_iterinit(myHash);
      while( HEntry = hv_iternext(myHash) ) {
        _unbless(HeVAL(HEntry), seen);
      }
      break;
    }
  }
  return sv;
}


/*

Returns objects within a data structure, deep first

*/
AV* _get_blessed(SV* sv, HV* seen, AV* objects) {
  I32 i;
  SV** AValue;
  HV* myHash;
  HE* HEntry;
  
  if (SvROK(sv)) {

    if (has_seen(sv, seen))
      return objects;
    _get_blessed(SvRV(sv), seen, objects);
    if (sv_isobject(sv)) {
      SvREFCNT_inc(sv);
      av_push(objects, sv);
    }
  
  } else {
    
    switch (SvTYPE(sv)) {
      case SVt_PVAV: {
        for(i = 0; i <= av_len((AV*) sv); i++) {
          AValue = av_fetch((AV*) sv, i, 0);
          _get_blessed(*AValue, seen, objects);
        }
        break;
      }
      case SVt_PVHV: {
        myHash = (HV*) sv;
        hv_iterinit(myHash);
        while( HEntry = hv_iternext(myHash) ) {
          _get_blessed(HeVAL(HEntry), seen, objects);
        }
        break;
      }
    }
  }
  
  return objects;
}



/*

Detects if there is a circular reference

*/
SV* _has_circular_ref(SV* sv, HV* seen, HV* parents) {

  SV* ret;
  SV* found;
  U32 len;
  I32 i;
  SV** AValue;
  HV* myHash;
  HE* HEntry;

  if (SvROK(sv)) { // Reference

    char addr[40];
    sprintf(addr, "%p", SvRV(sv));
    len = strlen(addr);
    
#ifdef SvWEAKREF
    if (! SvWEAKREF(sv)) {
#endif
      if (hv_exists(parents, addr, len)) {
        dsWARN("found a circular reference!!!");
        SvREFCNT_inc(sv);
        return sv;
      }
      hv_store(parents, addr, len,  NULL, 0);
#ifdef SvWEAKREF
    }
#endif
    
    if (has_seen(sv, seen))
      return &PL_sv_undef;
    
    ret = _has_circular_ref(SvRV(sv), seen, parents);
    hv_delete(parents, addr, (U32) len, 0);
    return ret;
  }

  // Not a reference
  switch (SvTYPE(sv)) {

    case SVt_PVAV: { // Array
      dsWARN("Array");
      for(i = 0; i <= av_len((AV*) sv); i++) {
        dsWARN("next elem");
        AValue = av_fetch((AV*) sv, i, 0);
        found = _has_circular_ref(*AValue, seen, parents);
        if (SvOK(found))
          return found;
      }
      break;
    }
    case SVt_PVHV: { // Hash
      dsWARN("Hash");
      myHash = (HV*) sv;
      hv_iterinit(myHash);
      while( HEntry = hv_iternext(myHash) ) {
        dsWARN("next key");
        found = _has_circular_ref(HeVAL(HEntry), seen, parents);
        if (SvOK(found))
          return found;
      }
      break;
    }
  }
  return &PL_sv_undef;
}


#if dsDEBUG
/*

Dump any data structure

*/

SV* _dump_any(SV* re, HV* seen, int depth) {

testvar:

  if (SvROK(re)) {
      if (has_seen(re, seen))
        return re;
      printf("a reference ");

      if (sv_isobject(re)) printf(" blessed ");

      printf("to ");
    	re = SvRV(re);
      goto testvar;
  
  } else {

    switch (SvTYPE(re)) {
      case SVt_NULL:
        printf("an undef value\n");
        break;
      case SVt_IV:
        printf("an integer (IV): %d\n", SvIV(re));
        break;
      case SVt_NV:
        printf("a double (NV): %f\n", SvNV(re));
        break;
      case SVt_RV:
        printf("a RV\n");
        break;
      case SVt_PV:
        printf("a string (PV): %s\n", SvPV_nolen(re));
        printf("UTF8 %s\n", SvUTF8(re) ? "on" : "off");
        break;
      case SVt_PVIV:
        printf("an integer (PVIV): %d\n", SvIV(re));
        break;
      case SVt_PVNV:
        printf("a string (PVNV): %s\n", SvPV_nolen(re));
        printf("UTF8 %s\n", SvUTF8(re) ? "on" : "off");
        break;
      case SVt_PVMG:
        printf("a PVMG\n");
        break;
      case SVt_PVLV:
        printf("a PVLV\n");
        break;
      case SVt_PVAV:
        printf("an array of %u elems (PVAV)\n", av_len((AV*) re) + 1);
        I32 i;
        for(i = 0; i <= av_len((AV*) re); i++) {
          SV** AValue = av_fetch((AV*) re, i, 0);
          printf("NEXT ELEM is ");
          _dump_any(*AValue, seen, depth);
        }
        break;
      
      case SVt_PVHV:
        printf("a hash (PVHV)\n");
        HV* myHash = (HV*) re;
        HE* HEntry;
        int count = 0;
        hv_iterinit(myHash);
        while( HEntry = hv_iternext(myHash) ) {
          count++;
          STRLEN len;
          char* HKey = HePV(HEntry, len);
          int i;
          for(i = 0; i < depth; i++)
            printf("\t");
          printf("NEXT KEY is %s, value is ", HKey);
          _dump_any(HeVAL(HEntry), seen, depth + 1);
        }
        if (! count) printf("Empty\n");
        break;
      
      case SVt_PVCV:
        printf("a code (PVCV)\n");
        return;
      case SVt_PVGV:
        printf("a glob (PVGV)\n");
        break;
      case SVt_PVBM:
        printf("a PVBM\n");
        break;
      case SVt_PVFM:
        printf("a PVFM\n");
        break;
      case SVt_PVIO:
        printf("a PVIO\n");
        break;
      default:
        if (SvOK(re)) {
          printf("Don't know what it is\n");
          return;
        } else {
          croak("Not a Sv");
          return;
        }
    }
  }
  return re;
}
#endif

//
// has_seen
// Returns true if ref already seen
//
int has_seen(SV* sv, HV* seen) {
  char addr[40];
  sprintf(addr, "%p", SvRV(sv));
  if (hv_exists(seen, addr, (U32) strlen(addr))) {
    dsWARN("already seen");
    return TRUE;
  } else {
    hv_store(seen, addr, (U32) strlen(addr),  NULL, 0);
    return FALSE;
  }
}




MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

bool
utf8_off_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    _utf8_set(sv, newHV(), 0);


MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

bool
utf8_on_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    RETVAL = _utf8_set(sv, newHV(), 1);
OUTPUT:
    RETVAL


MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

bool
has_utf8_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    RETVAL = _has_utf8(sv, newHV());
OUTPUT:
    RETVAL


MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

SV*
unbless_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    _unbless(sv, newHV());


MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

SV*
has_circular_ref_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    RETVAL = _has_circular_ref(sv, newHV(), newHV());
OUTPUT:
    RETVAL


MODULE = Data::Structure::Util     PACKAGE = Data::Structure::Util

AV*
get_blessed_xs(sv)
    SV* sv
PROTOTYPE: $
CODE:
    RETVAL = _get_blessed(sv, newHV(), newAV());
OUTPUT:
    RETVAL
