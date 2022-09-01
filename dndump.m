#import <AppKit/AppKit.h>

enum {
  Flag_Post = 1 << 0,
  Flag_Wait = 1 << 1,
  Flag_JSONObject = 1 << 2
};

void fail(const char* format, ...) {
  va_list va;
  va_start(va, format);
  vfprintf(stderr, format, va);
  exit(-1);
}

const char* objectToCString(id object) {
  return [[object description] cStringUsingEncoding: NSUTF8StringEncoding];
}

void writeObject(id data, id object) {
  if (object) {
    printf("[%s] %s\n", objectToCString(object), objectToCString(data));
  } else {
    printf("%s\n", objectToCString(data));
  }
}

int parseFlags(int* flags, int argc, const char** argv) {
  for (int i = 1; i < argc; ++i) {
    const char* arg = argv[i];
    if (arg[0] != '-') return i;
    for (int j = 1; arg[j]; ++j) {
      switch (arg[j]) {
        case 'p': *flags |= Flag_Post; break;
        case 'w': *flags |= Flag_Wait; break;
        case 'j': *flags |= Flag_JSONObject; break;
        default: printf("%s: unknown option %c\n", argv[0], arg[j]);
      }
    }
  }
  return argc;
}

int main(int argc, const char** argv) {
  int flags = 0;
  int i = parseFlags(&flags, argc, argv);
  if (i >= argc) fail("Usage: %s [-pw] <notificaitonName> [userInfoKeys...]\n", argv[0]);

  @autoreleasepool {
    NSString* notificaitonName = [NSString stringWithUTF8String: argv[i++]];
    NSMutableArray* keys = NSMutableArray.array;
    for (; i < argc; ++i) {
      [keys addObject: [NSString stringWithUTF8String: argv[i]]];
    }

    if (flags & Flag_Post) {
      id object = nil;
      NSMutableDictionary* userInfo = nil;
      NSUInteger count = keys.count;
      if (count) {
        if (count % 2) { fail("Expecting even number of keys\n"); count -= 1; }

        userInfo = [NSMutableDictionary dictionaryWithCapacity: count/2];
        for (NSUInteger k = 0; k < count; k += 2) {
          userInfo[keys[k]] = keys[k + 1];
        }
      }

      if (flags & Flag_JSONObject) {
        if (userInfo) {
          id err = nil;
          NSData* jsonData = [NSJSONSerialization dataWithJSONObject: userInfo options:0 error: &err];
          if (err) fail("Error while encoding json: %s\n", objectToCString(err));
          object = [NSString.alloc initWithData: jsonData encoding: NSUTF8StringEncoding];
          userInfo = nil;
        }
      }

      [NSDistributedNotificationCenter.defaultCenter postNotificationName: notificaitonName object: object userInfo: userInfo];
    } else {
      [NSDistributedNotificationCenter.defaultCenter addObserverForName: notificaitonName object: nil queue: NSOperationQueue.mainQueue usingBlock: ^(NSNotification* note) {
        id object = note.object;
        id userInfo = note.userInfo;

        if (flags & Flag_JSONObject) {
          if (object) {
            id err = nil;
            userInfo = [NSJSONSerialization JSONObjectWithData: [object dataUsingEncoding: NSUTF8StringEncoding] options: 0 error: &err];
            if (err) fail("Error while decoding json: %s\n", objectToCString(err));
            object = nil;
          } else {
            userInfo = nil;
          }
        }

        if (![userInfo isKindOfClass: NSDictionary.class]) {
          writeObject(userInfo, object);
        } else if (keys.count > 1) {
          writeObject([userInfo dictionaryWithValuesForKeys: keys], object);
        } else if (keys.count == 1) {
          writeObject([userInfo objectForKey: keys.firstObject], object);
        } else {
          writeObject(userInfo, object);
        }
        if (flags & Flag_Wait) [NSApp terminate: nil];
      }];
      [[NSApplication sharedApplication] run];
    }
  }

  return 0;
}
