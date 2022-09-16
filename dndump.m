#import <AppKit/AppKit.h>

enum {
  Flag_Post = 1 << 0,
  Flag_Listen = 1 << 1,
  Flag_Wait = 1 << 2,
  Flag_JSON = 1 << 3,
  Flag_AllSessions = 1 << 4
};

static int observerCount = 0;

static void fail(const char* format, ...) {
  va_list va;
  va_start(va, format);
  vfprintf(stderr, format, va);
  exit(-1);
}

static void warn(const char* format, ...) {
  va_list va;
  va_start(va, format);
  vfprintf(stdout, format, va);
}

static const char* objectToCString(id object) {
  return [[object description] cStringUsingEncoding: NSUTF8StringEncoding];
}

static void writeObject(id data, id object) {
  if (object) {
    printf("[%s] %s\n", objectToCString(object), objectToCString(data));
  } else {
    printf("%s\n", objectToCString(data));
  }
}

typedef void (^ObserverBlock)(id,id);

static void handleNotification(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo) {
  // NSLog(@"%@: %@[%@]", name, object, userInfo);
  ObserverBlock block = (__bridge ObserverBlock)observer;
  if (block) block((__bridge id)object, (__bridge id)userInfo);
}

static void execute(const char* bin, int flags, int savedFlags, NSString* notificationName, NSMutableArray* params) {
  // NSLog(@"%i: %@ [%@]", flags, notificationName, params);

  CFNotificationCenterRef center = CFNotificationCenterGetDistributedCenter();

  int fullFlags = flags | savedFlags;

  if (flags & Flag_Post) {
    CFOptionFlags options = kCFNotificationDeliverImmediately;
    if (fullFlags & Flag_AllSessions) options |= kCFNotificationPostToAllSessions;

    id object = nil;
    NSMutableDictionary* userInfo = nil;
    NSUInteger count = params.count;
    if (count) {
      if (count % 2) { fail("%s: expecting even number of params\n", bin); count -= 1; }

      userInfo = [NSMutableDictionary dictionaryWithCapacity: count/2];
      for (NSUInteger k = 0; k < count; k += 2) {
        userInfo[params[k]] = params[k + 1];
      }
    }

    if (fullFlags & Flag_JSON) {
      if (userInfo) {
        id err = nil;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject: userInfo options:0 error: &err];
        if (err) fail("%s: error while encoding json: %s\n", bin, objectToCString(err));
        object = [NSString.alloc initWithData: jsonData encoding: NSUTF8StringEncoding];
        userInfo = nil;
      }
    }

    CFNotificationCenterPostNotificationWithOptions(center,
      (__bridge CFStringRef)notificationName,
      (__bridge void*)object, (__bridge CFDictionaryRef)userInfo, options);
  } else {
    ObserverBlock observer = ^(id object, id userInfo) {
      if (fullFlags & Flag_JSON) {
        if (object) {
          id err = nil;
          @try {
            userInfo = [NSJSONSerialization JSONObjectWithData: [object dataUsingEncoding: NSUTF8StringEncoding] options: 0 error: &err];
            object = nil;
          } @catch (id e) {
            err = e;
          }
          if (err) warn("%s: error while decoding json: %s\n", bin, objectToCString(err));
        } else {
          userInfo = nil;
        }
      }

      if (![userInfo isKindOfClass: NSDictionary.class]) {
        writeObject(userInfo, object);
      } else if (params.count > 1) {
        writeObject([userInfo dictionaryWithValuesForKeys: params], object);
      } else if (params.count == 1) {
        writeObject([userInfo objectForKey: params.firstObject], object);
      } else {
        writeObject(userInfo, object);
      }

      if (fullFlags & Flag_Wait) exit(0);
    };

    CFNotificationCenterAddObserver(center, CFBridgingRetain([observer copy]),
      handleNotification,
      (__bridge CFStringRef)notificationName, nil, CFNotificationSuspensionBehaviorDeliverImmediately);

    observerCount += 1;
  }
}

int main(int argc, const char** argv) {
  @autoreleasepool {
    if (argc < 2) fail("Usage: %s [-jplwa] <notificaitonName> [parameters...]\n", argv[0]);

    int i = 1;
    int savedFlags = 0;
    int flags = 0;
    NSString* notificationName = nil;

    while (i < argc) {
      const char* arg = argv[i];
      if (arg[0] != '-') break;
      i += 1;
      if (!arg[1]) break;

      if (notificationName) execute(argv[0], flags, savedFlags, notificationName, nil);

      flags = 0;
      notificationName = nil;

      for (int j = 1; arg[j]; ++j) {
        switch (arg[j]) {
          case 'p': flags |= Flag_Post; break;
          case 'l': flags |= Flag_Listen; break;
          case 'w': flags |= Flag_Wait; break;
          case 'j': flags |= Flag_JSON; break;
          case 'a': flags |= Flag_AllSessions; break;
          default: fail("%s: unknown option %c\n", argv[0], arg[j]);
        }
      }

      if ((flags & Flag_Post) && (flags & (Flag_Listen|Flag_Wait))) {
        fail("%s: -p cannot be combined with -l or -w", argv[0]);
      }
      if ((flags & Flag_AllSessions) && (flags & (Flag_Listen|Flag_Wait))) {
        fail("%s: -a cannot be combined with -l or -w", argv[0]);
      }

      if (flags & (Flag_Post|Flag_Listen|Flag_Wait)) {
        if (i >= argc) fail("%s: expecting notification name after %s\n", argv[0], arg);
        notificationName = [NSString stringWithUTF8String: argv[i++]];
      } else {
        savedFlags |= flags;
      }
    }

    NSMutableArray* params = nil;
    if (i < argc) {
      params = [NSMutableArray.alloc initWithCapacity: argc - i];
      do { [params addObject: [NSString stringWithUTF8String: argv[i]]]; } while (++i < argc);

      if (!notificationName) {
        notificationName = params.firstObject;
        [params removeObjectAtIndex: 0];
      }
    }

    if (notificationName) execute(argv[0], flags, savedFlags, notificationName, params);
    if (observerCount) CFRunLoopRun();
    return 0;
  }
}
