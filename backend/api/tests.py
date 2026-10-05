from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from .models import User, Category, Post, SavedPost

class SignBoardAPITestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='testuser',
            email='test@signboard.com',
            first_name='Test',
            last_name='User'
        )
        self.category = Category.objects.create(
            id='tutoring',
            name='Tutoring',
            fields_schema=[
                {"id": "subject", "label": "Subject", "type": "text", "required": True},
                {"id": "monthly_fee", "label": "Monthly Fee", "type": "number", "required": True}
            ]
        )
        self.post = Post.objects.create(
            user=self.user,
            category=self.category,
            title='Calculus Tutor',
            description='Experienced calculus tutor',
            contact_whatsapp='+1234567890',
            structured_data={'subject': 'Calculus', 'monthly_fee': 200},
            latitude=23.7800,
            longitude=90.4100,
            address='Gulshan',
            city='Dhaka'
        )

    def test_categories_endpoint(self):
        url = reverse('category_list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(len(response.data) >= 1)
        self.assertEqual(response.data[0]['id'], 'tutoring')

    def test_posts_listing_and_distance(self):
        url = reverse('post_list_create')
        # Call with user coordinates
        response = self.client.get(url, {'latitude': 23.7850, 'longitude': 90.4150, 'sort': 'distance'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(len(response.data['results']) >= 1)
        post_item = response.data['results'][0]
        self.assertEqual(post_item['title'], 'Calculus Tutor')
        self.assertIsNotNone(post_item['distance_km'])

    def test_google_auth(self):
        url = reverse('google_auth')
        response = self.client.post(url, {
            'email': 'newuser@gmail.com',
            'name': 'New Google User',
            'google_id': 'goog_123456'
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('token', response.data)
        self.assertEqual(response.data['user']['email'], 'newuser@gmail.com')

    def test_create_post_with_structured_data(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('post_list_create')
        payload = {
            'category': 'tutoring',
            'title': 'Physics Home Tuition',
            'description': 'Targeting A-level physics students',
            'contact_whatsapp': '+1987654321',
            'structured_data': {
                'subject': 'Physics',
                'monthly_fee': 250
            },
            'latitude': 23.8103,
            'longitude': 90.4125,
            'address': 'Baridhara DOHS',
            'city': 'Dhaka'
        }
        response = self.client.post(url, payload, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['title'], 'Physics Home Tuition')

    def test_toggle_save_post(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('post_save_toggle', kwargs={'pk': self.post.id})
        # Save
        res1 = self.client.post(url)
        self.assertEqual(res1.status_code, status.HTTP_200_OK)
        self.assertTrue(res1.data['saved'])
        self.assertTrue(SavedPost.objects.filter(user=self.user, post=self.post).exists())

        # Unsave
        res2 = self.client.post(url)
        self.assertEqual(res2.status_code, status.HTTP_200_OK)
        self.assertFalse(res2.data['saved'])

    def test_delete_single_post(self):
        self.client.force_authenticate(user=self.user)
        url = reverse('post_detail', kwargs={'pk': self.post.id})
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Post.objects.filter(id=self.post.id).exists())

    def test_delete_all_my_posts(self):
        self.client.force_authenticate(user=self.user)
        # Create second post
        Post.objects.create(
            user=self.user,
            category=self.category,
            title='Another Post',
            contact_whatsapp='+1234567890',
            latitude=23.7,
            longitude=90.4
        )
        url = reverse('delete_all_my_posts')
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['success'], True)
        self.assertEqual(Post.objects.filter(user=self.user).count(), 0)

    def test_admin_stats_and_delete_post(self):
        admin_user = User.objects.create_superuser('admin_tester', 'adm@test.com', 'adminpass123')
        self.client.force_authenticate(user=admin_user)

        # Test admin stats
        stats_url = reverse('admin_stats')
        res_stats = self.client.get(stats_url)
        self.assertEqual(res_stats.status_code, status.HTTP_200_OK)
        self.assertIn('total_posts', res_stats.data)

        # Test admin deleting user's post
        post_del_url = reverse('admin_post_detail', kwargs={'pk': self.post.id})
        res_del = self.client.delete(post_del_url)
        self.assertEqual(res_del.status_code, status.HTTP_200_OK)
        self.assertFalse(Post.objects.filter(id=self.post.id).exists())

    def test_invalid_token_does_not_block_public_endpoints(self):
        # Client sends an old or invalid token header
        self.client.credentials(HTTP_AUTHORIZATION='Token completely_stale_or_invalid_token_xyz')
        cat_res = self.client.get(reverse('category_list'))
        self.assertEqual(cat_res.status_code, status.HTTP_200_OK)

        post_res = self.client.get(reverse('post_list_create'))
        self.assertEqual(post_res.status_code, status.HTTP_200_OK)

