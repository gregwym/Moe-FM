//
//  MFMPlayerManager.m
//  Moe FM
//
//  Created by Greg Wang on 12-7-5.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MFMPlayerManager.h"
#import "AudioStreamer.h"
#import "MFMResourcePlaylist.h"
#import "MFMResourceSong.h"

NSString * const MFMPlayerStatusChangedNotification = @"MFMPlayerStatusChangedNotification";
NSString * const MFMPlayerSongChangedNotification = @"MFMPlayerSongChangedNotification";

@interface MFMPlayerManager ()

@property (retain, atomic) MFMResourcePlaylist *playlist;
@property (assign, atomic) NSUInteger trackNum;
@property (retain, nonatomic) AudioStreamer *audioStreamer;
//@property (retain, nonatomic) AudioStreamer *lastStreamer;

@end

@implementation MFMPlayerManager

@synthesize nextPlaylist = _nextPlaylist;
@synthesize nextTrackNum = _nextTrackNum;
@synthesize playerStatus = _playerStatus;

@synthesize playlist = _playlist;
@synthesize trackNum = _trackNum;
@synthesize audioStreamer = _audioStreamer;

+ (MFMPlayerManager *)sharedPlayerManager
{
	static MFMPlayerManager *playerManager;
	if (playerManager == nil) {
		playerManager = [[MFMPlayerManager alloc] init];
		// Give it a magic playlist to begin
		MFMResourcePlaylist *resourcePlaylist = [MFMResourcePlaylist magicPlaylist];
		playerManager.nextPlaylist = resourcePlaylist;
		playerManager.nextTrackNum = 0;
		[playerManager start];
	}
	return playerManager;
}

- (MFMPlayerManager *)init
{
	self = [super init];
	if (self != nil) {
		self.nextPlaylist = nil;
		self.nextTrackNum = 0;
		self.playlist = nil;
		self.trackNum = 0;
		self.audioStreamer = nil;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:ASStatusChangedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:MFMResourceNotification object:nil];
	}
	return self;
}

#pragma mark - getter & setter

- (MFMResourceSong *)currentSong
{
	if (self.playlist == nil || self.playlist.resourceSongs == nil) {
		return nil;
	}
	return [self.playlist.resourceSongs objectAtIndex:self.trackNum];
}

#pragma mark - Player controls

- (AudioStreamer *)streamerWithURL:(NSURL *)url
{
	AudioStreamer *streamer = [AudioStreamer streamWithURL:url];
	// Do extra config to the streamer if needed
	return streamer;
}

- (void)createStreamer
{
	if (self.audioStreamer != nil)
	{
		return;
	}
	[self destroyStreamer];
	
	NSLog(@"Creating streamer");
	
	NSURL *url = self.currentSong.url;
	self.audioStreamer = [self streamerWithURL:url];
}

- (void)destroyStreamer
{
	if (self.audioStreamer != nil)
	{
		NSLog(@"Destroying streamer");
		AudioStreamer *streamer = self.audioStreamer;
		self.audioStreamer = nil;
		[streamer stop];
	}
}

- (void)prepareTrack
{
	self.trackNum = self.nextTrackNum;
	return;
}

- (void)preparePlaylist
{
	// Set playlist
	self.playlist = self.nextPlaylist;
	self.nextPlaylist = nil;
	
	// If nil playlist
	if (self.playlist == nil) {
		NSLog(@"Got nil playlist");
	}
	else {
		// Got new playlist, prepare to fetch resource
		
		// If start failed
		if ([self.playlist startFetch] == NO) {
			NSLog(@"Fail to start fetching");
			self.playlist = nil;
		}
		else {
			NSLog(@"Waiting for Playlist to ready");
		}
	}
}

- (BOOL)start
{
	if (self.nextPlaylist != nil && self.nextPlaylist != self.playlist) {
		[self stop];
		[self preparePlaylist];
		[self prepareTrack];
		return YES;
	}
	else if (self.nextTrackNum != self.trackNum) {
		[self stop];
		[self prepareTrack];
		[self play];
		return YES;
	}
	return NO;
}

- (BOOL)play
{
	// If no resource
	if (self.playlist.resourceSongs == nil) {
		// Wait for resource to load
		return NO;
	}
	
	// If no more song
	if (self.trackNum >= self.playlist.resourceSongs.count) {
		if ([self.playlist.mayHaveNext boolValue]) {
			NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@&", self.playlist.nextUrl]];
			self.nextPlaylist = [[MFMResourcePlaylist alloc] initWithURL:url];
			self.nextTrackNum = 0;
			[self start];
		}
		return NO;
	}
	
	// If have song and no streamer
	if (self.audioStreamer == nil) {
		[self createStreamer];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:MFMPlayerSongChangedNotification object:self];
	}
	
	if ([self.audioStreamer start] == NO) {
		return [self.audioStreamer play];
	} 
	
	return YES;
//	return [self.audioStreamer isPlaying] || [self.audioStreamer isWaiting];
}

- (BOOL)pause
{
	return [self.audioStreamer pause];
}

- (void)next
{
	if (self.playlist != nil && self.playlist.resourceSongs != nil) {
		self.nextTrackNum = self.trackNum + 1;
		[self start];
	}
}

- (void)stop
{
	[self destroyStreamer];
}

#pragma mark - NotificationCenter

- (void)handleNotification:(NSNotification *)notification
{
	if (notification.name == MFMResourceNotification) {
		[self handleNotificationFromResource:notification.object];
	}
	else if (notification.name == ASStatusChangedNotification) {
		[self handleNotificationFromStreamer:notification.object];
	}
}

- (void)handleNotificationFromResource:(MFMResource *)resource
{
	if (resource == self.playlist) {
		[self play];
	}
}

- (void)handleNotificationFromStreamer:(AudioStreamer *)streamer
{
	if (streamer == self.audioStreamer) {
		if (streamer.errorCode != AS_NO_ERROR) {
			// handle the error via a UI, retrying the stream, etc.
			NSLog(@"Streamer error: %@", [AudioStreamer stringForErrorCode:streamer.errorCode]);
			[self next];
		} else if ([streamer isPlaying]) {
			NSLog(@"Is Playing");
		} else if ([streamer isPaused]) {
			NSLog(@"Is Paused");
		} else if ([streamer isDone]) {
			NSLog(@"Is Done");
			[self next];
		} else if ([streamer isWaiting]){
			// stream is waiting for data, probably nothing to do
			NSLog(@"Is Waiting");
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:MFMPlayerStatusChangedNotification object:self];
	}
}

@end
