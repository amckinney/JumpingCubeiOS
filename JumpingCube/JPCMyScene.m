//
//  JPCMyScene.m
//  JumpingCube
//
//  Created by Maneesh Goel and Alex McKinney on 9/13/14.
//  Copyright (c) 2014 __MyCompanyName__. All rights reserved.
//

#import "JPCMyScene.h"
#import "JPCCube.h"
#import "JPCPlayer.h"
#import "SKScene+TouchPriority.h"
#import "JPCMyScene+CubeHelpers.h"
@interface JPCMyScene ()
@property (nonatomic, strong) SKNode *cubeLayer;
@property (nonatomic, weak) JPCPlayer *currentPlayer;
@property (nonatomic, strong) JPCPlayer *player1;
@property (nonatomic, strong) JPCPlayer *player2;
@property (nonatomic, strong) SKLabelNode *currentPlayerLabel;
@property (nonatomic, strong) SKLabelNode *playButtonH2H;
@property (nonatomic, strong) SKLabelNode *playButtonAI;
@end

@implementation JPCMyScene
-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor colorWithRed:250/256.0f green:248/256.0f blue:239/256.0f alpha:1.0f];
        _cubeLayer = [[SKNode alloc] init];
        _cubeLayer.name = @"cube layer";
        [self addChild:_cubeLayer];
        _player1 = [[JPCPlayer alloc] init];
        _player1.playerColor = [UIColor colorWithRed:45/256.0f green:99/256.0f blue:127/256.0f alpha:1.0f];
        _player2 = [[JPCPlayer alloc] init];
        _player2.playerColor = [UIColor colorWithRed:224/256.0f green:158/256.0f blue:025/256.0f alpha:1.0f];
        _currentPlayer = _player1;
        _currentPlayerLabel = [[SKLabelNode alloc] initWithFontNamed:@"DIN Alternate"];
        _currentPlayerLabel.fontColor = [UIColor darkGrayColor];
        _currentPlayerLabel.position = CGPointMake(160, 420);
        [self addChild:_currentPlayerLabel];
        
        _playButtonH2H = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _playButtonH2H.position = CGPointMake(80, 380);
        _playButtonH2H.fontColor = [UIColor darkGrayColor];
        _playButtonH2H.text = @"Play H2H";
        [self addChild:_playButtonH2H];
        
        _playButtonAI = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _playButtonAI.position = CGPointMake(240, 380);
        _playButtonAI.fontColor = [UIColor darkGrayColor];
        _playButtonAI.text = @"Play AI";
        [self addChild:_playButtonAI];
    }
    return self;
}

#pragma mark -
#pragma mark Game Management
-(void)newGame {
    _currentPlayerLabel.fontColor = [UIColor colorWithRed:45/256.0f green:99/256.0f blue:127/256.0f alpha:1.0f];
    _currentPlayerLabel.text = @"Blue's Move";
    [self.cubeLayer removeAllChildren];
    self.cubes = [[NSMutableArray alloc] initWithCapacity:16];
    for (int i = 0; i< 16; i++) {
        JPCCube *newCube = [[JPCCube alloc] initWithColor:[UIColor darkGrayColor] size:CGSizeMake(70, 70)];
        newCube.indexInArray = i;
        [self.cubes addObject:newCube];
        
    }
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            JPCCube *currentCube = self.cubes[4*i+j];
            currentCube.position = CGPointMake(47.5+j*75, 100+i*75);
            currentCube.neighborCount = [self neighbors:currentCube];
            [self.cubeLayer addChild:currentCube];
        }
    }
    self.currentPlayer = self.player1;
}

#pragma mark -
#pragma mark Turn Management
-(void)switchPlayer {
    if (self.currentPlayer == self.player1) {
        self.currentPlayer = self.player2;
        self.currentPlayerLabel.text = @"Gold's Move";
        self.currentPlayerLabel.fontColor = [UIColor colorWithRed:224/256.0f green:158/256.0f blue:025/256.0f alpha:1.0f];
        if (self.player2.AI) {
            NSMutableArray *currentCubes = [[NSMutableArray alloc] initWithCapacity:16];
            for (JPCCube *cube in self.cubes) {
                JPCCube *newCube = [[JPCCube alloc] initWithColor:cube.color size:cube.size];
                newCube.currentOwner = cube.currentOwner;
                newCube.score = cube.score;
                newCube.neighborCount = cube.neighborCount;
                newCube.indexInArray = cube.indexInArray;
                [currentCubes addObject:newCube];
            }
            SKAction *AIAction = [SKAction sequence:@[[SKAction waitForDuration:1], [SKAction runBlock:^(void) {
                int indexOfMove = [self.player2 minmax:currentCubes player:self.player2 depth:3];
                JPCCube *actionCube = self.cubes[indexOfMove];
                [self makeMove:actionCube withPlayer:self.player2];
                [self switchPlayer];
            }]]];
            [self runAction:AIAction];
        }
    } else {
        self.currentPlayer = self.player1;
        self.currentPlayerLabel.text = @"Blue's Move";
        self.currentPlayerLabel.fontColor = [UIColor colorWithRed:45/256.0f green:99/256.0f blue:127/256.0f alpha:1.0f];

    }
}

#pragma mark -
#pragma mark Touch Events
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!(self.player2.AI && self.currentPlayer == self.player2)) {
        for (UITouch *touch in touches) {
            CGPoint location = [touch locationInNode:self];
            if ([self nodeAtPoint:location] == self.playButtonH2H) {
                self.player2.AI = NO;
                [self newGame];
                self.playButtonH2H.hidden = YES;
                self.playButtonAI.hidden = YES;
                return;
            }
            if ([self nodeAtPoint:location] == self.playButtonAI) {
                self.player2.AI = YES;
                self.player2.opponentForAI = self.player1;
                [self newGame];
                self.playButtonH2H.hidden = YES;
                self.playButtonAI.hidden = YES;
            }
            JPCCube  *touchedCube = (JPCCube *)[self nodeWithHighestPriority:(NSSet *)touches];
            if ([touchedCube respondsToSelector:@selector(currentOwner)]) {
                if (self.currentPlayer == touchedCube.currentOwner || touchedCube.currentOwner == nil) {
                    [self makeMove:touchedCube withPlayer:self.currentPlayer];
                    [self switchPlayer];
                }
            }
        }
    }
}

#pragma mark -
#pragma mark Moves
-(void)makeMove:(JPCCube *)cube withPlayer:(JPCPlayer *)player
{
    if ([self.cubes indexOfObject:cube] != NSNotFound) {
        [cube cubeActionWithPlayer:player];
        if (cube.neighborCount < cube.score) {
            [self jump:cube withPlayer:player];
        }
    }
}

-(void)jump:(JPCCube *)cube withPlayer:(JPCPlayer *)player
{
    if (![self winnerExists]) {
        int square = (int)[self.cubes indexOfObject:cube];
        int row = [self rowValue:square];
        int col = [self colValue:square];
        cube.score -= [self neighbors:cube];
        
        NSMutableSet *indexInclusion = [[NSMutableSet alloc] initWithCapacity:16];
        for (int i = 0; i < 16; i++) {
            [indexInclusion addObject:@(i)];
        }
        SKAction *jumpAction = [SKAction sequence:@[[SKAction waitForDuration:0.1], [SKAction runBlock:^(void) {
            int index = [self squareValueAtRow:(row - 1) col:col];
            if ([indexInclusion containsObject:@(index)] && [self validRow:(row-1) col:col]) {
                [self makeMove:[self.cubes objectAtIndex:index] withPlayer:player];
            }
            index = [self squareValueAtRow:(row + 1) col:col];
            if ([indexInclusion containsObject:@(index)] && [self validRow:(row+1) col:col]) {
                [self makeMove:[self.cubes objectAtIndex:index] withPlayer:player];
            }
            index = [self squareValueAtRow:row col:(col - 1)];
            if ([indexInclusion containsObject:@(index)] && [self validRow:row col:(col-1)]) {
                [self makeMove:[self.cubes objectAtIndex:index] withPlayer:player];
                
            }
            index = [self squareValueAtRow:row col:col+1];
            if ([indexInclusion containsObject:@(index)] && [self validRow:row col:(col+1)]) {
                [self makeMove:[self.cubes objectAtIndex:index] withPlayer:player];
            }
        }], [SKAction runBlock:^(void) {
            if ([self winnerExists]) {
                if (self.currentPlayer != self.player1) {
                    self.currentPlayerLabel.text = @"Blue wins!";
                    self.currentPlayerLabel.fontColor = [UIColor colorWithRed:45/256.0f green:99/256.0f blue:127/256.0f alpha:1.0f];
                } else {
                    self.currentPlayerLabel.text = @"Gold wins!";
                    self.currentPlayerLabel.fontColor = [UIColor colorWithRed:224/256.0f green:158/256.0f blue:025/256.0f alpha:1.0f];
                }
                self.playButtonH2H.hidden = NO;
                self.playButtonAI.hidden = NO;
            }
        }]]];
        [self runAction:jumpAction];
    }
}
@end
