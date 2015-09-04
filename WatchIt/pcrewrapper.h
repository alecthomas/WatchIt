//
//  pcrewrapper.h
//  WatchIt
//
//  Created by Alec Thomas on 4/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

#ifndef pcrewrapper_h
#define pcrewrapper_h

// Necessary because Swift can't call function pointers (eg. pcre_free).
void pcre_free_wrapper(void*);

#endif /* pcrewrapper_h */
