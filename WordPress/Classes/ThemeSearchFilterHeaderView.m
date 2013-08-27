/*
 * ThemeSearchFilterHeaderView.m
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "ThemeSearchFilterHeaderView.h"
#import "ThemeBrowserViewController.h"
#import "WPStyleGuide.h"

CGFloat const SortButtonWidth = 120.0f;

@interface ThemeSearchFilterHeaderView () <UISearchBarDelegate>

@property (nonatomic, weak) UIView *sortOptionsView;
@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, weak) UIButton *sortButton;
@property (nonatomic, weak) UIImage *sortArrow, *sortArrowActive;

@end

@implementation ThemeSearchFilterHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [WPStyleGuide readGrey];
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width - SortButtonWidth, self.bounds.size.height)];
        _searchBar = searchBar;
        _searchBar.placeholder = NSLocalizedString(@"Search", @"");
        _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _searchBar.delegate = self;
        [_searchBar setTintColor:[WPStyleGuide readGrey]];
        [self addSubview:_searchBar];
    }
    return self;
}

- (void)layoutSubviews {
    // Adjust sort button due to hack below since auto resizing is not effective anymore
    _sortButton.frame = (CGRect) {
        .origin = CGPointMake(self.frame.size.width - SortButtonWidth, _sortButton.frame.origin.y),
        .size = _sortButton.frame.size
    };
    _sortOptionsView.frame = (CGRect) {
        .origin = CGPointMake(_sortButton.frame.origin.x, _sortOptionsView.frame.origin.y),
        .size = _sortOptionsView.frame.size
    };
}

- (void)setDelegate:(ThemeBrowserViewController *)delegate {
    _delegate = delegate;
    
    UIView *sortOptions = self.sortOptionsView;
    
#warning make this proper
    id hackView = nil;
    for (id view in _delegate.view.subviews) {
        if ([view isKindOfClass:[UICollectionView class]]) {
            hackView = view;
            [view addSubview:sortOptions];
            break;
        }
    }
    
    UIButton *sortButton = self.sortButton;
    [hackView addSubview:sortButton]; // adding to hackview causes loss of magical rotation layout changes
}

- (UIButton*)sortOptionButtonWithTitle:(NSString*)title {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:@selector(optionPressed:) forControlEvents:UIControlEventTouchUpInside];
    button.exclusiveTouch = true;
    button.titleLabel.font = [WPStyleGuide regularTextFont];
    return button;
}

- (UIView *)sortOptionsView {
    UIView *optionsContainer = [[UIView alloc] init];
    _sortOptionsView = optionsContainer;
    _sortOptionsView.backgroundColor = [WPStyleGuide allTAllShadeGrey];
    _sortOptionsView.alpha = 0;
    _sortOptionsView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    CGFloat yOffset = 0;
    for (NSUInteger i = 0; i < [_delegate themeSortingOptions].count; i++) {
        UIButton *option = [self sortOptionButtonWithTitle:[_delegate themeSortingOptions][i]];
        option.frame = CGRectMake(0, yOffset, SortButtonWidth, self.bounds.size.height);
        option.tag = i;
        yOffset += option.frame.size.height;
        [_sortOptionsView addSubview:option];
    }
    _sortOptionsView.frame = CGRectMake(_searchBar.frame.size.width, -yOffset, SortButtonWidth, yOffset);
    return _sortOptionsView;
}

- (UIButton *)sortButton {
    UIImage *arrow = [UIImage imageNamed:@"icon-themes-dropdown-arrow"];
    _sortArrow = arrow;
    UIImage *arrowActive = [UIImage imageWithCGImage:arrow.CGImage scale:arrow.scale orientation:UIImageOrientationDown];
    _sortArrowActive = arrowActive;
    
    UIButton *sort = [UIButton buttonWithType:UIButtonTypeCustom];
    _sortButton = sort;
    [_sortButton setBackgroundColor:[WPStyleGuide allTAllShadeGrey]];
    [_sortButton setTitle:[_delegate themeSortingOptions][0] forState:UIControlStateNormal];
    _sortButton.titleLabel.font = [WPStyleGuide regularTextFont];
    [_sortButton setImage:_sortArrow forState:UIControlStateNormal];
    _sortButton.imageEdgeInsets = UIEdgeInsetsMake(0, 95, 0, 0);
    _sortButton.titleEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 28);
    _sortButton.frame = CGRectMake(_searchBar.frame.size.width, 0, SortButtonWidth, self.bounds.size.height);
    [_sortButton addTarget:self action:@selector(sortPressed) forControlEvents:UIControlEventTouchUpInside];
    return _sortButton;
}

- (void)sortPressed {
    CGFloat yOffset = _sortOptionsView.frame.origin.y < 0 ? self.bounds.size.height : -_sortOptionsView.frame.size.height;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        _sortOptionsView.alpha = yOffset > 0 ? 1.0f : 0;
        _sortOptionsView.frame = (CGRect) {
            .origin = CGPointMake(_sortOptionsView.frame.origin.x, yOffset),
            .size = CGSizeMake(SortButtonWidth, _sortOptionsView.bounds.size.height)
        };
        [_sortButton setImage:(yOffset > 0 ? _sortArrowActive : _sortArrow) forState:UIControlStateNormal];
    } completion:nil];
}

- (void)optionPressed:(UIButton*)sender {
    [self.sortButton setTitle:[_delegate themeSortingOptions][sender.tag] forState:UIControlStateNormal];
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        _sortOptionsView.frame = (CGRect) {
            .origin = CGPointMake(_sortOptionsView.frame.origin.x, -_sortOptionsView.frame.size.height),
            .size = CGSizeMake(SortButtonWidth, _sortOptionsView.bounds.size.height)
        };
        _sortOptionsView.alpha = 0;
        [_sortButton setImage:_sortArrow forState:UIControlStateNormal];
    } completion:nil];
    
    [_delegate selectedSortIndex:sender.tag];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    searchBar.showsCancelButton = true;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (!searchBar.text || [searchBar.text isEqualToString:@""]) {
        searchBar.showsCancelButton = false;
        [_delegate clearSearchFilter];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [_delegate applyFilterWithSearchText:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [_delegate clearSearchFilter];
    searchBar.showsCancelButton = false;
}

@end