//
//  Created by Tony Arnold on 10/04/2014.
//  Copyright (c) 2014 QMMagical Panda Software LLC. All rights reserved.
//

#define QM_DEPRECATED_WILL_BE_REMOVED_IN(VERSION) __attribute__((deprecated("This method has been deprecated and will be removed in QMMagicalRecord " VERSION ".")))
#define QM_DEPRECATED_WILL_BE_REMOVED_IN_PLEASE_USE(VERSION, METHOD) __attribute__((deprecated("This method has been deprecated and will be removed in QMMagicalRecord " VERSION ". Please use `" METHOD "` instead.")))
