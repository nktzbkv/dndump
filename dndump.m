#import <AppKit/AppKit.h>

void fail(const char* format, ...) {
  va_list va;
  va_start(va, format);
  vfprintf(stderr, format, va);
  exit(-1);
}

void writeObject(id object) {
  printf("%s\n", [[object description] cStringUsingEncoding: NSUTF8StringEncoding]);
}

enum {
  Flag_Post = 1 << 0,
  Flag_Wait = 1 << 1,
};

int parseFlags(int* flags, int argc, const char** argv) {
  for (int i = 1; i < argc; ++i) {
    const char* arg = argv[i];
    if (arg[0] != '-') return i;
    for (int j = 1; arg[j]; ++j) {
      switch (arg[j]) {
        case 'p': *flags |= Flag_Post; break;
        case 'w': *flags |= Flag_Wait; break;
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
      NSMutableDictionary* userInfo = nil;
      NSUInteger count = keys.count;
      if (count) {
        if (count % 2) { fail("Expecting even number of keys\n"); count -= 1; }

        userInfo = [NSMutableDictionary dictionaryWithCapacity: count/2];
        for (NSUInteger k = 0; k < count; k += 2) {
          userInfo[keys[k]] = keys[k + 1];
        }
      }

      [NSDistributedNotificationCenter.defaultCenter postNotificationName: notificaitonName object: nil userInfo: userInfo];
    } else {
      [NSDistributedNotificationCenter.defaultCenter addObserverForName: notificaitonName object: nil queue: NSOperationQueue.mainQueue usingBlock: ^(NSNotification* note) {
        if (keys.count > 1) {
          writeObject([note.userInfo dictionaryWithValuesForKeys: keys]);
        } else if (keys.count == 1) {
          writeObject([note.userInfo objectForKey: keys.firstObject]);
        } else {
          writeObject(note.userInfo);
        }
        if (flags & Flag_Wait) [NSApp terminate: nil];
      }];
      [[NSApplication sharedApplication] run];
    }
  }

  return 0;
}
