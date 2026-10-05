from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from rest_framework.authtoken.models import Token
from api.models import Category, Post, SavedPost

User = get_user_model()

CATEGORIES_SCHEMA = [
    {
        "id": "tutoring",
        "name": "Tutoring",
        "icon": "school",
        "order": 1,
        "fields": [
            {"id": "subject", "label": "Subject / Topic", "type": "text", "required": True, "placeholder": "e.g. Higher Math, Physics"},
            {"id": "student_level", "label": "Target Class / Level", "type": "text", "required": True, "placeholder": "e.g. Class 9-12 / O-Level"},
            {"id": "monthly_fee", "label": "Monthly Fee ($)", "type": "number", "required": True, "placeholder": "e.g. 150"},
            {"id": "days_per_week", "label": "Days Per Week", "type": "select", "options": ["2 Days", "3 Days", "4 Days", "5 Days"], "required": True},
        ]
    },
    {
        "id": "teachers",
        "name": "Teachers",
        "icon": "person_outline",
        "order": 2,
        "fields": [
            {"id": "subject_expertise", "label": "Subject Expertise", "type": "text", "required": True, "placeholder": "e.g. English Literature"},
            {"id": "qualification", "label": "Highest Degree", "type": "text", "required": True, "placeholder": "e.g. M.Sc in Mathematics"},
            {"id": "experience_years", "label": "Teaching Experience", "type": "text", "required": True, "placeholder": "e.g. 8 Years"},
            {"id": "hourly_rate", "label": "Hourly Rate ($)", "type": "number", "required": False, "placeholder": "e.g. 35"},
        ]
    },
    {
        "id": "used-products",
        "name": "Used Products",
        "icon": "shopping_bag",
        "order": 3,
        "fields": [
            {"id": "item_name", "label": "Item Name", "type": "text", "required": True, "placeholder": "e.g. Sony Bravia 55' 4K TV"},
            {"id": "condition", "label": "Item Condition", "type": "select", "options": ["Brand New (Boxed)", "Like New", "Good Condition", "Fair / Used"], "required": True},
            {"id": "price", "label": "Price ($)", "type": "number", "required": True, "placeholder": "e.g. 420"},
            {"id": "is_negotiable", "label": "Price Negotiable?", "type": "select", "options": ["Yes (Negotiable)", "Fixed Price"], "required": True},
        ]
    },
    {
        "id": "self-services",
        "name": "Self Services",
        "icon": "build",
        "order": 4,
        "fields": [
            {"id": "service_name", "label": "Service Title", "type": "text", "required": True, "placeholder": "e.g. AC Repair & Servicing"},
            {"id": "pricing_model", "label": "Pricing Structure", "type": "select", "options": ["Fixed Inspection Fee", "Hourly Rate", "Job-based Quotation"], "required": True},
            {"id": "availability", "label": "Availability", "type": "select", "options": ["24/7 Emergency", "Daily 9 AM - 8 PM", "Weekends Only"], "required": True},
        ]
    },
    {
        "id": "plumbing",
        "name": "Plumbing",
        "icon": "plumbing",
        "order": 5,
        "fields": [
            {"id": "service_type", "label": "Plumbing Type", "type": "select", "options": ["Pipe Leakage", "Sanitary Installation", "Drainage Unclogging", "Complete Fitting"], "required": True},
            {"id": "callout_fee", "label": "Visiting / Inspection Fee ($)", "type": "number", "required": True, "placeholder": "e.g. 20"},
            {"id": "service_guarantee", "label": "Work Guarantee", "type": "select", "options": ["30 Days Warranty", "90 Days Warranty", "No Warranty"], "required": False},
        ]
    },
    {
        "id": "sell-house",
        "name": "Sell House",
        "icon": "home",
        "order": 6,
        "fields": [
            {"id": "property_type", "label": "Property Type", "type": "select", "options": ["Apartment", "Duplex Villa", "Independent Building"], "required": True},
            {"id": "bedrooms", "label": "Bedrooms", "type": "select", "options": ["1 Bed", "2 Bed", "3 Bed", "4 Bed", "5+ Bed"], "required": True},
            {"id": "bathrooms", "label": "Bathrooms", "type": "select", "options": ["1 Bath", "2 Bath", "3 Bath", "4+ Bath"], "required": True},
            {"id": "total_sqft", "label": "Total Area (Sq Ft)", "type": "number", "required": True, "placeholder": "e.g. 1850"},
            {"id": "price", "label": "Asking Price ($)", "type": "number", "required": True, "placeholder": "e.g. 250000"},
        ]
    },
    {
        "id": "sell-property",
        "name": "Sell Property",
        "icon": "terrain",
        "order": 7,
        "fields": [
            {"id": "land_type", "label": "Plot / Land Type", "type": "select", "options": ["Residential Plot", "Commercial Land", "Industrial Plot"], "required": True},
            {"id": "plot_size", "label": "Plot Size (Katha / Sq Ft)", "type": "text", "required": True, "placeholder": "e.g. 5 Katha (3600 sqft)"},
            {"id": "road_width", "label": "Front Road Width (Feet)", "type": "number", "required": False, "placeholder": "e.g. 40"},
            {"id": "price", "label": "Total Price ($)", "type": "number", "required": True, "placeholder": "e.g. 180000"},
        ]
    },
    {
        "id": "rent-rooms",
        "name": "Rent Rooms",
        "icon": "hotel",
        "order": 8,
        "fields": [
            {"id": "room_type", "label": "Room Type", "type": "select", "options": ["Single Bed Room", "Master Bed Room (Attached Bath)", "Shared Room", "Studio Apartment"], "required": True},
            {"id": "monthly_rent", "label": "Monthly Rent ($)", "type": "number", "required": True, "placeholder": "e.g. 350"},
            {"id": "floor_no", "label": "Floor Level", "type": "text", "required": True, "placeholder": "e.g. 4th Floor (With Lift)"},
            {"id": "available_from", "label": "Available From", "type": "text", "required": True, "placeholder": "e.g. 1st of Next Month"},
        ]
    },
    {
        "id": "rent-garage",
        "name": "Rent Garage",
        "icon": "garage",
        "order": 9,
        "fields": [
            {"id": "vehicle_capacity", "label": "Vehicle Capacity", "type": "select", "options": ["1 SUV / Sedan", "2 Cars", "Motorcycle only", "Commercial Van"], "required": True},
            {"id": "monthly_rent", "label": "Monthly Rent ($)", "type": "number", "required": True, "placeholder": "e.g. 120"},
            {"id": "security", "label": "Security Features", "type": "select", "options": ["CCTV + Guard", "CCTV Only", "Gated Compound"], "required": False},
        ]
    },
    {
        "id": "car-rental",
        "name": "Car Rental",
        "icon": "directions_car",
        "order": 10,
        "fields": [
            {"id": "vehicle_model", "label": "Vehicle Model", "type": "text", "required": True, "placeholder": "e.g. Toyota Prado / Allion 2022"},
            {"id": "daily_rate", "label": "Daily Rental Rate ($)", "type": "number", "required": True, "placeholder": "e.g. 60"},
            {"id": "driver_included", "label": "Driver Included?", "type": "select", "options": ["With Professional Driver", "Self-Drive Only", "Both Available"], "required": True},
            {"id": "fuel_policy", "label": "Fuel Policy", "type": "select", "options": ["Renter pays fuel", "Included in rate"], "required": False},
        ]
    },
    {
        "id": "homemade-food",
        "name": "Homemade Food",
        "icon": "restaurant",
        "order": 11,
        "fields": [
            {"id": "dish_specialty", "label": "Signature Dishes", "type": "text", "required": True, "placeholder": "e.g. Hyderabadi Biryani, Healthy Lunch Box"},
            {"id": "meal_type", "label": "Meal Type", "type": "select", "options": ["Daily Lunch Box", "Dinner Catering", "Party Orders", "Desserts & Cakes"], "required": True},
            {"id": "avg_price", "label": "Average Price / Meal ($)", "type": "number", "required": True, "placeholder": "e.g. 8"},
            {"id": "delivery", "label": "Home Delivery", "type": "select", "options": ["Free Home Delivery", "Self-Pickup", "Delivery with courier fee"], "required": True},
        ]
    },
    {
        "id": "matrimonial",
        "name": "Matrimonial services",
        "icon": "favorite",
        "order": 12,
        "fields": [
            {"id": "profile_for", "label": "Looking For", "type": "select", "options": ["Bride (Female)", "Groom (Male)"], "required": True},
            {"id": "age_range", "label": "Age", "type": "text", "required": True, "placeholder": "e.g. 27 Years"},
            {"id": "profession", "label": "Profession", "type": "text", "required": True, "placeholder": "e.g. Software Engineer / Doctor"},
            {"id": "education", "label": "Education Level", "type": "text", "required": True, "placeholder": "e.g. Masters in CS"},
        ]
    },
    {
        "id": "others",
        "name": "Others",
        "icon": "more_horiz",
        "order": 13,
        "fields": [
            {"id": "service_overview", "label": "Service / Need Description", "type": "text", "required": True, "placeholder": "Describe what you offer or need"},
            {"id": "budget", "label": "Estimated Budget ($)", "type": "number", "required": False, "placeholder": "e.g. 100"},
        ]
    },
]

SAMPLE_POSTS = [
    {
        "category_id": "tutoring",
        "title": "Expert Math & Physics Tutoring",
        "description": "Expert math tutoring for high school students. 10+ years of experience with excellent results. Conceptual clear understanding and board exam preparation.",
        "contact_whatsapp": "+12345678901",
        "structured_data": {
            "subject": "Higher Mathematics & Physics",
            "student_level": "Grade 9-12 / A-Levels",
            "monthly_fee": "180",
            "days_per_week": "3 Days"
        },
        "latitude": 23.7925,
        "longitude": 90.4078,
        "address": "Banani Road 11, Block D",
        "city": "Dhaka"
    },
    {
        "category_id": "used-products",
        "title": "Gently Used Electronics & Appliances",
        "description": "Gently used electronics and home appliances. All items are tested and in excellent condition with 3 days testing warranty.",
        "contact_whatsapp": "+12345678902",
        "structured_data": {
            "item_name": "Sony Bravia 55' 4K Ultra HD TV",
            "condition": "Like New",
            "price": "450",
            "is_negotiable": "Yes (Negotiable)"
        },
        "latitude": 23.7950,
        "longitude": 90.4120,
        "address": "Gulshan 2 Avenue, North Tower",
        "city": "Dhaka"
    },
    {
        "category_id": "rent-rooms",
        "title": "Spacious Master Bedroom with Attached Bath",
        "description": "Well ventilated sunny master bedroom with attached bathroom and private balcony. Clean family apartment with 24/7 generator and lift.",
        "contact_whatsapp": "+12345678903",
        "structured_data": {
            "room_type": "Master Bed Room (Attached Bath)",
            "monthly_rent": "320",
            "floor_no": "5th Floor (Lift available)",
            "available_from": "1st of Next Month"
        },
        "latitude": 23.7808,
        "longitude": 90.4167,
        "address": "Niketan Block E, Near Lakeside",
        "city": "Dhaka"
    },
    {
        "category_id": "plumbing",
        "title": "Professional Emergency Plumbing & Sanitary",
        "description": "Certified master plumber available for all emergency water pipe leakage, geyser installation, and high-pressure motor pump setup.",
        "contact_whatsapp": "+12345678904",
        "structured_data": {
            "service_type": "Sanitary Installation & Pipe Leakage",
            "callout_fee": "25",
            "service_guarantee": "30 Days Warranty"
        },
        "latitude": 23.7744,
        "longitude": 90.3956,
        "address": "Mohakhali Wireless Gate",
        "city": "Dhaka"
    },
    {
        "category_id": "homemade-food",
        "title": "Fresh Hygienic Daily Lunch Catering",
        "description": "Cooked fresh everyday with pure mustard oil and farm ingredients. Customizable weekly lunch subscription for office executives and students.",
        "contact_whatsapp": "+12345678905",
        "structured_data": {
            "dish_specialty": "Steamed Rice, Fish/Chicken Curry, Dal & Bhaji",
            "meal_type": "Daily Lunch Box",
            "avg_price": "6",
            "delivery": "Free Home Delivery"
        },
        "latitude": 23.7533,
        "longitude": 90.3872,
        "address": "Dhanmondi Road 27",
        "city": "Dhaka"
    },
    {
        "category_id": "car-rental",
        "title": "Toyota Allion 2022 with Driver",
        "description": "Super clean AC car with polite professional driver. Available for round trips, airport pickups, and inter-city travels.",
        "contact_whatsapp": "+12345678906",
        "structured_data": {
            "vehicle_model": "Toyota Allion 2022",
            "daily_rate": "55",
            "driver_included": "With Professional Driver",
            "fuel_policy": "Renter pays fuel"
        },
        "latitude": 23.8103,
        "longitude": 90.4125,
        "address": "Baridhara DOHS Main Gate",
        "city": "Dhaka"
    },
    {
        "category_id": "sell-house",
        "title": "Luxury 3-Bed 2200 Sqft Modern Apartment",
        "description": "South-facing apartment with natural air circulation, imported marble flooring, 2 dedicated car parking spots, and rooftop community hall.",
        "contact_whatsapp": "+12345678907",
        "structured_data": {
            "property_type": "Apartment",
            "bedrooms": "3 Bed",
            "bathrooms": "4 Bath",
            "total_sqft": "2200",
            "price": "290000"
        },
        "latitude": 23.8683,
        "longitude": 90.3973,
        "address": "Uttara Sector 7, Lake Drive",
        "city": "Dhaka"
    }
]

class Command(BaseCommand):
    help = 'Seeds initial categories, schemas, and sample signboard posts'

    def handle(self, *args, **kwargs):
        self.stdout.write("Seeding categories...")
        cat_map = {}
        for item in CATEGORIES_SCHEMA:
            cat, _ = Category.objects.update_or_create(
                id=item['id'],
                defaults={
                    'name': item['name'],
                    'icon': item['icon'],
                    'order': item['order'],
                    'fields_schema': item['fields']
                }
            )
            cat_map[cat.id] = cat
        self.stdout.write(self.style.SUCCESS(f"Successfully seeded {len(cat_map)} categories."))

        # Create demo user Maya Johnson (as in Figma design)
        demo_user, created = User.objects.get_or_create(
            username='maya_johnson',
            defaults={
                'email': 'maya.j@example.com',
                'first_name': 'Maya',
                'last_name': 'Johnson',
                'avatar_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
                'phone_number': '+12345678901',
                'whatsapp_number': '+12345678901',
                'subscription_tier': 'free'
            }
        )
        Token.objects.get_or_create(user=demo_user)
        self.stdout.write(self.style.SUCCESS(f"Demo user '{demo_user.email}' ready."))

        # Seed sample posts
        self.stdout.write("Seeding sample posts...")
        for p_data in SAMPLE_POSTS:
            cat = cat_map.get(p_data['category_id'])
            if not cat:
                continue
            post, _ = Post.objects.get_or_create(
                title=p_data['title'],
                defaults={
                    'user': demo_user,
                    'category': cat,
                    'description': p_data['description'],
                    'contact_whatsapp': p_data['contact_whatsapp'],
                    'structured_data': p_data['structured_data'],
                    'latitude': p_data['latitude'],
                    'longitude': p_data['longitude'],
                    'address': p_data['address'],
                    'city': p_data['city'],
                    'is_active': True
                }
            )
        self.stdout.write(self.style.SUCCESS("All seed posts created successfully!"))
