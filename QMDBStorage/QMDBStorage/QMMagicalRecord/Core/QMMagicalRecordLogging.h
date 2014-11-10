//
//  QMMagicalRecordLogging.h
//  QMMagicalRecord
//
//  Created by Saul Mora on 10/4/13.
//  Copyright (c) 2013 QMMagical Panda Software LLC. All rights reserved.
//

#ifndef QMMagicalRecord_QMMagicalRecordLogging_h
#define QMMagicalRecord_QMMagicalRecordLogging_h

#import "QMMagicalRecord.h"
#import "QMMagicalRecord+Options.h"

#define LOG_ASYNC_ENABLED YES

#define LOG_ASYNC_ERROR   ( NO && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_WARN    (YES && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_INFO    (YES && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_VERBOSE (YES && LOG_ASYNC_ENABLED)

#ifndef QM_LOGGING_CONTEXT
    #define QM_LOGGING_CONTEXT 0
#endif

#ifdef QM_LOGGING_ENABLED

#ifndef LOG_MACRO

    #define LOG_MACRO(isAsynchronous, lvl, flg, ctx, atag, fnct, frmt, ...) \
    NSLog (frmt, ##__VA_ARGS__)

    #define LOG_MAYBE(async, lvl, flg, ctx, fnct, frmt, ...) \
    do { if ((lvl & flg) == flg) { LOG_MACRO(async, lvl, flg, ctx, nil, fnct, frmt, ##__VA_ARGS__); } } while(0)

    #define LOG_OBJC_MAYBE(async, lvl, flg, ctx, frmt, ...) \
    LOG_MAYBE(async, lvl, flg, ctx, sel_getName(_cmd), frmt, ##__VA_ARGS__)

    #define LOG_C_MAYBE(async, lvl, flg, ctx, frmt, ...) \
    LOG_MAYBE(async, lvl, flg, ctx, __FUNCTION__, frmt, ##__VA_ARGS__)

#endif

#define QMMRLogFatal(frmt, ...)   LOG_OBJC_MAYBE(LOG_ASYNC_ERROR,   [QMMagicalRecord loggingLevel], QMMagicalRecordLoggingMaskFatal,   QM_LOGGING_CONTEXT, frmt, ##__VA_ARGS__)
#define QMMRLogError(frmt, ...)   LOG_OBJC_MAYBE(LOG_ASYNC_ERROR,   [QMMagicalRecord loggingLevel], QMMagicalRecordLoggingMaskError,   QM_LOGGING_CONTEXT, frmt, ##__VA_ARGS__)
#define QMMRLogWarn(frmt, ...)    LOG_OBJC_MAYBE(LOG_ASYNC_WARN,    [QMMagicalRecord loggingLevel], QMMagicalRecordLoggingMaskWarn,    QM_LOGGING_CONTEXT, frmt, ##__VA_ARGS__)
#define QMMRLogInfo(frmt, ...)    LOG_OBJC_MAYBE(LOG_ASYNC_INFO,    [QMMagicalRecord loggingLevel], QMMagicalRecordLoggingMaskInfo,    QM_LOGGING_CONTEXT, frmt, ##__VA_ARGS__)
#define QMMRLogVerbose(frmt, ...) LOG_OBJC_MAYBE(LOG_ASYNC_VERBOSE, [QMMagicalRecord loggingLevel], QMMagicalRecordLoggingMaskVerbose, QM_LOGGING_CONTEXT, frmt, ##__VA_ARGS__)

#define QMMRLogCFatal(frmt, ...)   LOG_C_MAYBE(LOG_ASYNC_ERROR,   [QMMagicalRecord loggingLevel], QMMagicalRecordLoggingMaskFatal,   QM_LOGGING_CONTEXT, frmt, ##__VA_ARGS__)
#define QMMRLogCError(frmt, ...)   LOG_C_MAYBE(LOG_ASYNC_ERROR,   [QMMagicalRecord loggingLevel], QMMagicalRecordLoggingMaskError,   QM_LOGGING_CONTEXT, frmt, ##__VA_ARGS__)
#define QMMRLogCWarn(frmt, ...)    LOG_C_MAYBE(LOG_ASYNC_WARN,    [QMMagicalRecord loggingLevel], QMMagicalRecordLoggingMaskWarn,    QM_LOGGING_CONTEXT, frmt, ##__VA_ARGS__)
#define QMMRLogCInfo(frmt, ...)    LOG_C_MAYBE(LOG_ASYNC_INFO,    [QMMagicalRecord loggingLevel], QMMagicalRecordLoggingMaskInfo,    QM_LOGGING_CONTEXT, frmt, ##__VA_ARGS__)
#define QMMRLogCVerbose(frmt, ...) LOG_C_MAYBE(LOG_ASYNC_VERBOSE, [QMMagicalRecord loggingLevel], QMMagicalRecordLoggingMaskVerbose, QM_LOGGING_CONTEXT, frmt, ##__VA_ARGS__)

#else

#define QMMRLogFatal(frmt, ...) ((void)0)
#define QMMRLogError(frmt, ...) ((void)0)
#define QMMRLogWarn(frmt, ...) ((void)0)
#define QMMRLogInfo(frmt, ...) ((void)0)
#define QMMRLogVerbose(frmt, ...) ((void)0)

#define QMMRLogCFatal(frmt, ...) ((void)0)
#define QMMRLogCError(frmt, ...) ((void)0)
#define QMMRLogCWarn(frmt, ...) ((void)0)
#define QMMRLogCInfo(frmt, ...) ((void)0)
#define QMMRLogCVerbose(frmt, ...) ((void)0)

#endif

#endif

