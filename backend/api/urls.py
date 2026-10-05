from django.urls import path
from .views import (
    GoogleAuthView, UserProfileView, CategoryListView,
    PostListCreateView, PostDetailView, ToggleSavePostView,
    SavedPostsListView, MyPostsListView, DeleteAllMyPostsView,
    AdminLoginView, AdminStatsView, AdminUserListView, AdminPostManageView
)

urlpatterns = [
    # Auth
    path('auth/google/', GoogleAuthView.as_view(), name='google_auth'),
    path('auth/profile/', UserProfileView.as_view(), name='user_profile'),

    # Categories
    path('categories/', CategoryListView.as_view(), name='category_list'),

    # Posts
    path('posts/', PostListCreateView.as_view(), name='post_list_create'),
    path('posts/<uuid:pk>/', PostDetailView.as_view(), name='post_detail'),
    path('posts/<uuid:pk>/save/', ToggleSavePostView.as_view(), name='post_save_toggle'),
    path('posts/saved/', SavedPostsListView.as_view(), name='saved_posts'),
    path('posts/my/', MyPostsListView.as_view(), name='my_posts'),
    path('posts/my/delete-all/', DeleteAllMyPostsView.as_view(), name='delete_all_my_posts'),

    # Admin Management Site APIs
    path('admin/login/', AdminLoginView.as_view(), name='admin_login'),
    path('admin/stats/', AdminStatsView.as_view(), name='admin_stats'),
    path('admin/users/', AdminUserListView.as_view(), name='admin_users'),
    path('admin/users/<uuid:pk>/', AdminUserListView.as_view(), name='admin_user_detail'),
    path('admin/posts/', AdminPostManageView.as_view(), name='admin_posts'),
    path('admin/posts/<uuid:pk>/', AdminPostManageView.as_view(), name='admin_post_detail'),
]

