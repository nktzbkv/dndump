#import <AppKit/AppKit.h>

void usage(const char** argv) {
	printf("Usage: %s [notificaitonName] [userInfoKeys...]\n", argv[0]);
	exit(-1);
}

void writeObject(id object) {
	printf("%s\n", [[object description] cStringUsingEncoding: NSUTF8StringEncoding]);
}

int main(int argc, const char** argv) {
	if (argc < 2) usage(argv);

	@autoreleasepool {
		NSString* notificaitonName = [NSString stringWithCString: argv[1] encoding: NSUTF8StringEncoding];

		NSMutableArray* keys = NSMutableArray.array;
		for (int i = 2; i < argc; ++i) {
			[keys addObject: [NSString stringWithCString: argv[i] encoding: NSUTF8StringEncoding]];
		}

		[NSDistributedNotificationCenter.defaultCenter addObserverForName: notificaitonName object: nil queue: NSOperationQueue.mainQueue usingBlock: ^(NSNotification* note) {
			if (keys.count > 1) {
				writeObject([note.userInfo dictionaryWithValuesForKeys: keys]);
			} else if (keys.count == 1) {
				writeObject([note.userInfo objectForKey: keys.firstObject]);
			} else {
				writeObject(note.userInfo);
			}
		}];
		[[NSApplication sharedApplication] run];
	}

	return 0;
}
