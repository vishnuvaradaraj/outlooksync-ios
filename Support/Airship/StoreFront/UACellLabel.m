/*
Copyright 2009 Urban Airship Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binaryform must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation 
and/or other materials provided withthe distribution.

THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// Based on ASKit label by Shaun Harrison on 10/27/08. Copyright 2008 enormego.

#import "UACellLabel.h"


@implementation UACellLabel

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		self.shadowColor = [UIColor colorWithWhite:1.0f alpha:0.52f];
		self.shadowOffset = CGSizeMake(0.0f, 1.0f);
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder {
	if((self = [super initWithCoder:aDecoder])) {
		self.shadowColor = [UIColor colorWithWhite:1.0f alpha:0.52f];
		self.shadowOffset = CGSizeMake(0.0f, 1.0f);
	}
	
	return self;
}

- (void)setHighlighted:(BOOL)highlighted {
	if(highlighted) {
		self.shadowColor = [UIColor clearColor];
	} else {
		self.shadowColor = [UIColor colorWithWhite:1.0f alpha:0.52f];
	}
	
	[super setHighlighted:highlighted];
}

@end
