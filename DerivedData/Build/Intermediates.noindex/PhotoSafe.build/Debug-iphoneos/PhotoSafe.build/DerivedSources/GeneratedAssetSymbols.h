#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "Logo" asset catalog image resource.
static NSString * const ACImageNameLogo AC_SWIFT_PRIVATE = @"Logo";

/// The "NoImageFound" asset catalog image resource.
static NSString * const ACImageNameNoImageFound AC_SWIFT_PRIVATE = @"NoImageFound";

#undef AC_SWIFT_PRIVATE
