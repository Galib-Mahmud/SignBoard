import random
import uuid
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from rest_framework.authtoken.models import Token
from api.models import Category, Post
from api.management.commands.seed_data import CATEGORIES_SCHEMA

User = get_user_model()

# Realistic hubs in Dhaka & major urban areas
LOCATIONS = [
    {"city": "Dhaka", "area": "Dhanmondi Road 27", "lat": 23.7538, "lng": 90.3776},
    {"city": "Dhaka", "area": "Gulshan-2 Circle", "lat": 23.7946, "lng": 90.4143},
    {"city": "Dhaka", "area": "Banani Road 11", "lat": 23.7937, "lng": 90.4048},
    {"city": "Dhaka", "area": "Uttara Sector 3", "lat": 23.8681, "lng": 90.3984},
    {"city": "Dhaka", "area": "Uttara Sector 11", "lat": 23.8742, "lng": 90.3921},
    {"city": "Dhaka", "area": "Mirpur 10 Roundabout", "lat": 23.8072, "lng": 90.3686},
    {"city": "Dhaka", "area": "Mirpur 1 Sony Cinema Hall", "lat": 23.7956, "lng": 90.3537},
    {"city": "Dhaka", "area": "Bashundhara R/A Block C", "lat": 23.8151, "lng": 90.4255},
    {"city": "Dhaka", "area": "Mohammadpur Ring Road", "lat": 23.7658, "lng": 90.3584},
    {"city": "Dhaka", "area": "Panthapath Green Road", "lat": 23.7511, "lng": 90.3882},
    {"city": "Dhaka", "area": "Badda Pragati Sarani", "lat": 23.7806, "lng": 90.4267},
    {"city": "Dhaka", "area": "Motijheel C/A", "lat": 23.7330, "lng": 90.4172},
    {"city": "Chittagong", "area": "GEC Circle", "lat": 22.3592, "lng": 91.8215},
    {"city": "Sylhet", "area": "Zindabazar", "lat": 24.8968, "lng": 91.8687},
]

USERS_POOL = [
    {"email": "maya.j@example.com", "name": "Maya Johnson", "phone": "+8801711223344", "avatar": "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150"},
    {"email": "tahmid.h@example.com", "name": "Engr. Tahmid Hasan", "phone": "+8801812345678", "avatar": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150"},
    {"email": "sumaiya.a@example.com", "name": "Sumaiya Akter", "phone": "+8801911445566", "avatar": "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150"},
    {"email": "rafiqul.i@example.com", "name": "Dr. Rafiqul Islam", "phone": "+8801722334455", "avatar": "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150"},
    {"email": "nusrat.j@example.com", "name": "Nusrat Jahan", "phone": "+8801611889900", "avatar": "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150"},
    {"email": "kamrul.h@example.com", "name": "Kamrul Hassan", "phone": "+8801755667788", "avatar": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150"},
    {"email": "farzana.y@example.com", "name": "Farzana Yeasmin", "phone": "+8801922338899", "avatar": "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150"},
]

CATEGORY_TEMPLATES = {
    "tutoring": {
        "titles": [
            "HSC & SSC Higher Math & Physics Home Tutor",
            "O/A Level Cambridge Mathematics & Mechanics Specialist",
            "English Medium Class 6-10 All Science Subjects Private Tutor",
            "Admission Test Preparation - Engineering & Medical Foundations",
            "IELTS 8.0+ Band Coaching with Native Pronunciation & Mock Tests",
            "Class 9-12 Chemistry & Biology Concept-Building Home Coaching",
            "Primary School All Subjects Caring Lady Tutor",
            "Computer Programming & Python for Beginners & High School Students",
        ],
        "descriptions": [
            "Experienced faculty member offering tailored conceptual guidance with weekly exam evaluations, chapter-wise mock tests, and comprehensive doubt-clearing sessions. Both offline home tutoring and online interactive batches available.",
            "Specialized coaching focused on past papers, problem-solving speed, and deep understanding of mathematical derivations. Flexible scheduling on weekdays and weekend options.",
            "Dedicated mentor helping students achieve academic excellence through structured lesson plans, interactive quizzes, and personalized attention to weak topics.",
        ],
        "data_gen": lambda: {
            "subject": random.choice(["Higher Math", "Physics", "Chemistry", "English Literature", "Biology", "Computer Science"]),
            "student_level": random.choice(["Class 9-10 (SSC)", "Class 11-12 (HSC)", "O-Level", "A-Level", "University Admission"]),
            "monthly_fee": str(random.choice([4000, 6000, 8000, 10000, 12000, 15000])),
            "days_per_week": random.choice(["2 Days", "3 Days", "4 Days", "5 Days"]),
        }
    },
    "teachers": {
        "titles": [
            "Senior Lecturer in Physics & Engineering Mechanics",
            "Certified IELTS & Spoken English Corporate Trainer",
            "M.Sc in Applied Mathematics with 10+ Years College Teaching",
            "PhD Candidate in Computer Science Offering Data Structures & Algorithms",
            "Ex-Notre Dame College Faculty Member for Higher Secondary Physics",
        ],
        "descriptions": [
            "Over a decade of academic teaching experience with recognized pedagogical credentials. Providing specialized group workshops, individual mentorship, and institutional guest lecturing.",
            "Proven track record of preparing hundreds of top-scoring candidates for board exams, university admissions, and international language certifications.",
        ],
        "data_gen": lambda: {
            "subject_expertise": random.choice(["Physics", "Mathematics", "English", "Chemistry", "Computer Science"]),
            "qualification": random.choice(["M.Sc in Physics (DU)", "M.Sc in Mathematics (BUET)", "MA in English (JU)", "B.Sc in CSE"]),
            "experience_years": f"{random.randint(4, 15)} Years",
            "hourly_rate": str(random.choice([15, 25, 35, 50, 75])),
        }
    },
    "used-products": {
        "titles": [
            "Sony Bravia 55' 4K HDR Smart Google TV (Boxed)",
            "Apple MacBook Air M2 (16GB RAM, 512GB SSD) Space Gray",
            "Canon EOS R6 Mirrorless Camera with 24-105mm Lens Kit",
            "Herman Miller Ergonomic Executive Office Chair",
            "Yamaha F310 Acoustic Guitar with Padded Gig Bag & Tuner",
            "Dell UltraSharp 27-inch 4K USB-C Color Accurate Monitor",
            "Samsung Galaxy S23 Ultra 256GB Phantom Black (Official)",
        ],
        "descriptions": [
            "Maintained in pristine working condition with zero scratches, fully functional ports, original packaging box, power brick, and purchase receipt. Available for in-person inspection and thorough testing.",
            "Carefully used in a smoke-free home studio environment. Battery health is above 92%. Genuine buyers are welcome to test before final purchase.",
        ],
        "data_gen": lambda: {
            "item_name": random.choice(["Sony 55 4K TV", "MacBook Air M2", "Canon EOS R6", "Ergonomic Office Chair", "Yamaha Guitar", "Dell 27 4K Monitor"]),
            "condition": random.choice(["Brand New (Boxed)", "Like New", "Good Condition"]),
            "price": str(random.choice([250, 450, 750, 1100, 1400])),
            "is_negotiable": random.choice(["Yes (Negotiable)", "Fixed Price"]),
        }
    },
    "self-services": {
        "titles": [
            "Inverter AC Deep Jet Washing & Gas Refilling Service",
            "Professional Laptop Motherboard Repair & Thermal Paste Servicing",
            "Home Interior Painting, Texture & Wall Damp Proofing",
            "Electrician On Call - Short Circuit Detection & DB Fitting",
            "Deep Sofa & Carpet Steam Cleaning with Organic Shampoos",
        ],
        "descriptions": [
            "Certified technician equipped with high-pressure diagnostic and cleaning equipment. Transparent pricing, same-day scheduling, and 30-day service satisfaction warranty included.",
            "Fast doorstep service across the metropolitan area with genuine replacement parts and upfront pricing quotation.",
        ],
        "data_gen": lambda: {
            "service_name": random.choice(["AC Jet Wash & Gas Topup", "Laptop Hardware Servicing", "Wall Painting & Damp Proofing", "Electrical Wiring Repair"]),
            "pricing_model": random.choice(["Fixed Inspection Fee", "Hourly Rate", "Job-based Quotation"]),
            "availability": random.choice(["24/7 Emergency", "Daily 9 AM - 8 PM", "Weekends Only"]),
        }
    },
    "plumbing": {
        "titles": [
            "Emergency Concealed Pipe Leakage Detection & Repair",
            "Sanitary Ware & Geyser Water Heater Installation Expert",
            "Kitchen Sink & Sewer Line Hydro-Jet Drain Cleaning",
            "Bathroom Master Renovation & PPR Pipe Line Fitting",
        ],
        "descriptions": [
            "Master plumber with 12+ years experience in modern residential towers and commercial buildings. Equipped with acoustic leak detectors and heavy drain augers.",
            "Prompt response to all plumbing emergencies. High quality PPR/CPVC fittings guaranteed against future leaks.",
        ],
        "data_gen": lambda: {
            "service_type": random.choice(["Pipe Leakage", "Sanitary Installation", "Drainage Unclogging", "Complete Fitting"]),
            "callout_fee": str(random.choice([15, 20, 25, 30])),
            "service_guarantee": random.choice(["30 Days Warranty", "90 Days Warranty"]),
        }
    },
    "sell-house": {
        "titles": [
            "2150 Sq Ft Luxurious South Facing 3-BHK Apartment with 2 Car Parks",
            "1850 Sq Ft Ready Brand New Flat with Double Balconies & Panoramic View",
            "Independent 3-Storied Duplex Villa with Private Rooftop Garden",
            "3200 Sq Ft Penthouse Suite with Dedicated Elevator Access & Servant Room",
        ],
        "descriptions": [
            "Architecturally designed residential unit featuring imported Spanish tiles, European fittings, full standby generator backup, 24/7 CCTV surveillance, and prime wide road frontage.",
            "Prime location close to leading schools, hospitals, and transit points. Clean legal documentation with verified mutation and tax clearances.",
        ],
        "data_gen": lambda: {
            "property_type": random.choice(["Apartment", "Duplex Villa", "Independent Building"]),
            "bedrooms": random.choice(["2 Bed", "3 Bed", "4 Bed", "5+ Bed"]),
            "bathrooms": random.choice(["2 Bath", "3 Bath", "4+ Bath"]),
            "total_sqft": str(random.choice([1450, 1850, 2150, 2600, 3200])),
            "price": str(random.choice([120000, 185000, 250000, 380000])),
        }
    },
    "sell-property": {
        "titles": [
            "5 Katha Prime Commercial Corner Plot Facing 60 Ft Wide Avenue",
            "10 Katha South-East Facing Residential Land in Gated Society",
            "3 Katha Immediate Ready-to-Build Land with Gas & Electricity Feeds",
        ],
        "descriptions": [
            "High-value freehold plot with all legal utility connections nearby, demarcation boundary wall, and clear mutation deeds ready for instant registration.",
            "Outstanding investment opportunity situated in an upscale urban expansion zone with high projected capital appreciation.",
        ],
        "data_gen": lambda: {
            "land_type": random.choice(["Residential Plot", "Commercial Land", "Industrial Plot"]),
            "plot_size": random.choice(["3 Katha", "5 Katha", "7.5 Katha", "10 Katha"]),
            "road_width": str(random.choice([25, 40, 60, 80])),
            "price": str(random.choice([85000, 150000, 280000, 450000])),
        }
    },
    "rent-rooms": {
        "titles": [
            "Fully Furnished Master Bedroom with Attached Bath & Balcony for Rent",
            "Independent Single Studio Room for Professional or Student with WiFi",
            "Semi-Furnished Spacious Bedroom in 4th Floor Luxury Flat (Lift + Gen)",
            "Executive Shared Room with Maid Service, Meals & High-Speed Internet",
        ],
        "descriptions": [
            "Cozy, calm, and quiet residential space equipped with high-speed fiber internet, generator backup, filtered drinking water, and round-the-clock building security.",
            "Walking distance from main bus stops and grocery stores. Ideal for working professionals or university scholars seeking peace of mind.",
        ],
        "data_gen": lambda: {
            "room_type": random.choice(["Master Bed Room (Attached Bath)", "Single Bed Room", "Studio Apartment", "Shared Room"]),
            "monthly_rent": str(random.choice([150, 220, 320, 450])),
            "floor_no": random.choice(["2nd Floor", "3rd Floor", "4th Floor (With Lift)", "6th Floor"]),
            "available_from": random.choice(["Immediate", "1st of Next Month", "Within 15 Days"]),
        }
    },
    "rent-garage": {
        "titles": [
            "Dedicated Covered Parking Space for Large SUV in Gated Apartment",
            "Basement Car Garage with CCTV Security, Auto-Shutter & Wash Facility",
            "Ground Floor Secure Motorcycle Parking Spot with 24/7 Guard",
        ],
        "descriptions": [
            "Spacious, well-lit covered parking bay with wide drive-in ramp, continuous CCTV monitoring, guard round checking, and hose wash availability.",
            "Easily accessible for sedans or SUVs. Secure gated access keycard provided to the tenant.",
        ],
        "data_gen": lambda: {
            "vehicle_capacity": random.choice(["1 SUV / Sedan", "2 Cars", "Motorcycle only"]),
            "monthly_rent": str(random.choice([60, 90, 120, 160])),
            "security": random.choice(["CCTV + Guard", "Gated Compound"]),
        }
    },
    "car-rental": {
        "titles": [
            "Toyota Allion / Premio 2022 with Experienced Chauffeur for Intercity Trips",
            "Toyota HiAce Super GL Microbus (11 Seats) for Family Tours & Corporate Use",
            "Toyota Prado TX 4WD Luxury SUV for VIP Delegation & Weddings",
            "Honda Grace Hybrid for Daily City Commute & Airport Pick/Drop",
        ],
        "descriptions": [
            "Immaculately maintained vehicle with ice-cold dual AC, courteous licensed driver, safety airbags, and flexible daily or weekly booking packages. Toll and fuel policies clearly detailed.",
            "Punctual, dependable transport service catering to city tours, corporate delegacies, and outstation holiday trips.",
        ],
        "data_gen": lambda: {
            "vehicle_model": random.choice(["Toyota Allion 2022", "Toyota HiAce Super GL", "Toyota Prado 4WD", "Honda Grace Hybrid"]),
            "daily_rate": str(random.choice([40, 65, 95, 140])),
            "driver_included": random.choice(["With Professional Driver", "Both Available"]),
            "fuel_policy": random.choice(["Renter pays fuel", "Included in rate"]),
        }
    },
    "homemade-food": {
        "titles": [
            "Traditional Kacchi Biryani & Borhani Weekend Family Platter",
            "Healthy Diet Home-Cooked Daily Lunch Box for Office Executives",
            "Authentic Bengali Fish Curry, Bhorta & Steamed Rice Meal Plan",
            "Artisan Chocolate Fudge & Vanilla Sponge Birthday Cakes (Custom Made)",
        ],
        "descriptions": [
            "Prepared with fresh farm produce, pure spices, and low oil under rigorous hygienic home conditions. Free doorstep delivery or hot insulated container transport available.",
            "Specialized monthly lunch and dinner subscription packages tailored for busy executives desiring genuine mom-style cooking.",
        ],
        "data_gen": lambda: {
            "dish_specialty": random.choice(["Kacchi Biryani & Borhani", "Healthy Diet Lunch Box", "Bengali Fish & Bhorta", "Custom Birthday Cakes"]),
            "meal_type": random.choice(["Daily Lunch Box", "Dinner Catering", "Party Orders"]),
            "avg_price": str(random.choice([6, 8, 12, 18])),
            "delivery": random.choice(["Free Home Delivery", "Delivery with courier fee"]),
        }
    },
    "matrimonial": {
        "titles": [
            "Looking for Educated & Religious Groom for Software Engineer Bride (26)",
            "Groom Profile: BCS Cadre Officer (29), Looking for Cultured Graduate Bride",
            "Bride Profile: Medical Doctor (MBBS, 27), Seeking Well-Settled Groom in Dhaka",
            "Groom Profile: Senior Solutions Architect in Canada (31), Looking for Bride",
        ],
        "descriptions": [
            "Respectable and practicing Muslim family seeking a compatible partner of good character, strong family values, and noble educational standing. Serious family inquiries only.",
            "Family values mutual respect and understanding. Bio-data and horoscope/photos exchanged upon direct WhatsApp contact.",
        ],
        "data_gen": lambda: {
            "profile_for": random.choice(["Bride (Female)", "Groom (Male)"]),
            "age_range": f"{random.randint(24, 34)} Years",
            "profession": random.choice(["Software Engineer", "Doctor (MBBS)", "BCS Cadre Officer", "Banker / Finance Manager", "Architect"]),
            "education": random.choice(["B.Sc / M.Sc in Engineering", "MBBS / FCPS", "MBA (IBA)", "Masters in Business"]),
        }
    },
    "others": {
        "titles": [
            "Professional Legal Documentation, Land Mutation & Registration Assistance",
            "Professional Drone Videography & Photography for Commercial Projects",
            "Custom Wooden Furniture Design, Polishing & Upholstery Restoration",
            "Translation & Notary Services (English, Bengali, Arabic, French)",
        ],
        "descriptions": [
            "Experienced professional providing reliable, cost-effective, and verified solutions. Initial consultation and project cost estimates provided upfront without hidden charges.",
            "Committed to timely execution and client satisfaction across all project scopes.",
        ],
        "data_gen": lambda: {
            "service_overview": random.choice(["Legal mutation service", "Drone aerial videography", "Custom wooden carpentry", "Certified legal translation"]),
            "budget": str(random.choice([50, 100, 200, 350, 500])),
        }
    },
}


class Command(BaseCommand):
    help = "Bulk seed posts for hyper-scale performance testing (e.g. 1000 posts per category)"

    def add_arguments(self, parser):
        parser.add_argument(
            '--count',
            type=int,
            default=1000,
            help='Number of posts to generate per category (default: 1000)'
        )
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing posts before seeding'
        )

    def handle(self, *args, **options):
        per_category_count = options['count']
        clear_first = options['clear']

        self.stdout.write(self.style.NOTICE(f"=== Starting High-Scale Bulk Seeding ({per_category_count} posts/category) ==="))

        # 1. Ensure Categories are seeded
        categories = {}
        for cat_data in CATEGORIES_SCHEMA:
            cat, _ = Category.objects.get_or_create(
                id=cat_data["id"],
                defaults={
                    "name": cat_data["name"],
                    "icon": cat_data["icon"],
                    "order": cat_data["order"],
                    "fields_schema": cat_data["fields"],
                }
            )
            categories[cat.id] = cat
        self.stdout.write(self.style.SUCCESS(f"Categories verified: {len(categories)} categories ready."))

        # 2. Ensure Users Pool exists
        users = []
        for u_data in USERS_POOL:
            user, _ = User.objects.get_or_create(
                email=u_data["email"],
                defaults={
                    "username": u_data["email"].split('@')[0],
                    "first_name": u_data["name"].split(' ')[0],
                    "last_name": u_data["name"].split(' ')[-1],
                    "avatar_url": u_data["avatar"],
                    "phone_number": u_data["phone"],
                    "whatsapp_number": u_data["phone"],
                }
            )
            Token.objects.get_or_create(user=user)
            users.append(user)

        # 3. Create Admin Superuser if not exists
        admin_user, created = User.objects.get_or_create(
            username="admin",
            defaults={
                "email": "admin@signboard.com",
                "first_name": "Site",
                "last_name": "Admin",
                "is_staff": True,
                "is_superuser": True,
                "avatar_url": "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150",
            }
        )
        if created or not admin_user.check_password("adminpassword123"):
            admin_user.set_password("adminpassword123")
            admin_user.is_staff = True
            admin_user.is_superuser = True
            admin_user.save()
        Token.objects.get_or_create(user=admin_user)
        self.stdout.write(self.style.SUCCESS(f"Admin superuser verified: 'admin' / 'adminpassword123'"))

        if clear_first:
            self.stdout.write(self.style.WARNING("Clearing existing posts..."))
            Post.objects.all().delete()

        # 4. Generate Posts in bulk batches
        total_created = 0
        batch_size = 1000

        for cat_id, cat_obj in categories.items():
            tmpl = CATEGORY_TEMPLATES.get(cat_id, CATEGORY_TEMPLATES["others"])
            posts_to_create = []

            for i in range(per_category_count):
                user = random.choice(users)
                loc = random.choice(LOCATIONS)
                title_base = random.choice(tmpl["titles"])
                desc_base = random.choice(tmpl["descriptions"])
                
                # Add human-readable variation so titles and listings are unique and realistic
                var_code = (i % 500) + 1
                title = f"{title_base} - #{var_code}" if i > 0 else title_base
                
                # Subtle GPS variation around the area coordinate (within ~1.5 km radius)
                lat_offset = random.uniform(-0.015, 0.015)
                lng_offset = random.uniform(-0.015, 0.015)
                
                struct_data = tmpl["data_gen"]()

                post = Post(
                    id=uuid.uuid4(),
                    user=user,
                    category=cat_obj,
                    title=title,
                    description=f"{desc_base}\n\n• Location: {loc['area']}, {loc['city']}\n• Contact Person: {user.first_name} {user.last_name}\n• Verified Local Listing #SB-{cat_id[:3].upper()}-{1000 + i}",
                    contact_whatsapp=user.whatsapp_number or user.phone_number or "+8801711223344",
                    structured_data=struct_data,
                    latitude=round(loc["lat"] + lat_offset, 6),
                    longitude=round(loc["lng"] + lng_offset, 6),
                    address=f"{loc['area']}, {loc['city']}",
                    city=loc["city"],
                    views_count=random.randint(5, 450),
                    is_active=True,
                )
                posts_to_create.append(post)

                if len(posts_to_create) >= batch_size:
                    Post.objects.bulk_create(posts_to_create)
                    total_created += len(posts_to_create)
                    posts_to_create = []

            if posts_to_create:
                Post.objects.bulk_create(posts_to_create)
                total_created += len(posts_to_create)

            self.stdout.write(self.style.SUCCESS(f"  ✓ {cat_obj.name}: Generated {per_category_count} high-fidelity posts."))

        self.stdout.write(self.style.SUCCESS(f"\n🎉 Successfully seeded {total_created} posts across all {len(categories)} categories!"))
