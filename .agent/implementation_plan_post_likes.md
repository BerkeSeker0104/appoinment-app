
# Implementation Plan - Post Like Feature

I have implemented the post liking feature as requested.

## Changes

1.  **API Constant**: Added `postLikes` endpoint to `ApiConstants` in `lib/core/constants/api_constants.dart`.
2.  **Service**: Created `PostLikeApiService` in `lib/data/services/post_like_api_service.dart` to handle the `POST` request to `/api/post-likes`.
3.  **Model**: Updated `PostModel` in `lib/data/models/post_model.dart` to include `isLiked` (bool) and `likeCount` (int). I also updated `fromJson` and `copyWith`.
4.  **UI**: Modified `BarberDetailPage` in `lib/presentation/pages/customer/barber_detail_page.dart`.
    *   Imported `PostLikeApiService`.
    *   Updated `_PostDetailModalState` to manage `isLiked` and `likeCount` state locally.
    *   Added a "Like" button (heart icon) and like count text to the post detail view.
    *   Implemented `_toggleLike` method with optimistic UI updates and error handling.
    *   Added a "Share" button placeholder as well for better UX.

## Verification

The user can now tap on a post in the barber detail page.
Inside the post detail modal, they will see a heart icon.
Tapping the heart icon will:
1.  Instantaneously toggle the icon state (filled/outline) and update the count.
2.  Send a POST request to the backend.
3.  If the request fails, it will revert the UI state and show a snackbar.
