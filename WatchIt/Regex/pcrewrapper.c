//
//  pcrewrapper.c
//  WatchIt
//
//  Created by Alec Thomas on 4/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

#include <stdio.h>
#include "pcrewrapper.h"
#include "/usr/local/include/pcre.h"


void pcre_free_wrapper(void *ptr) {
    pcre_free(ptr);
}