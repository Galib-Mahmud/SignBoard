/**
 * SignBoard Web Application Logic
 * High-performance state management, live API integration & fallback resilience.
 */

const RENDER_PROD_API = 'https://signboard-backend.onrender.com/api';

function resolveApiBase() {
  const isHttps = window.location.protocol === 'https:';
  const isVercel = window.location.hostname.includes('vercel.app');
  const stored = localStorage.getItem('signboard_api_base');
  
  // If on Vercel or remote HTTPS, strictly use live Render cloud
  if (isHttps || isVercel) {
    if (!stored || !stored.startsWith('https://')) {
      localStorage.setItem('signboard_api_base', RENDER_PROD_API);
      return RENDER_PROD_API;
    }
    return stored;
  }
  
  // On localhost:
  return stored || 'http://127.0.0.1:8000/api';
}

// State Management
const STATE = {
  apiBase: resolveApiBase(),
  authToken: localStorage.getItem('signboard_auth_token') || '',
  adminToken: localStorage.getItem('signboard_admin_token') || '',
  adminUser: JSON.parse(localStorage.getItem('signboard_admin_user') || 'null'),
  
  userLocation: {
    lat: 23.7538,
    lng: 90.3776,
    city: 'Dhaka',
    area: 'Dhanmondi Road 27',
  },
  
  categories: [],
  selectedCategory: 'all',
  searchQuery: '',
  sortBy: 'recent',
  
  posts: [],
  savedPosts: JSON.parse(localStorage.getItem('signboard_saved_ids') || '[]'),
  myPosts: [],
  
  isBackendLive: false,
};

// DOM Element References
const DOM = {
  // Tabs
  navTabs: document.querySelectorAll('.nav-tab'),
  tabContents: document.querySelectorAll('.tab-content'),
  discoveryBar: document.getElementById('discovery-bar'),
  
  // Status & GPS
  gpsText: document.getElementById('gps-display-text'),
  apiDot: document.getElementById('api-status-dot'),
  apiLabel: document.getElementById('api-label-text'),
  btnRefreshGps: document.getElementById('btn-refresh-gps'),
  btnApiConfig: document.getElementById('btn-api-config'),
  
  // Search & Categories
  searchInput: document.getElementById('global-search-input'),
  btnClearSearch: document.getElementById('btn-clear-search'),
  catContainer: document.getElementById('categories-container'),
  sortSelect: document.getElementById('sort-select'),
  
  // Containers
  postsContainer: document.getElementById('posts-container'),
  savedContainer: document.getElementById('saved-posts-container'),
  myPostsContainer: document.getElementById('my-posts-container'),
  
  // Badges & Counters
  savedCounter: document.getElementById('saved-counter'),
  myPostsCounter: document.getElementById('my-posts-counter'),
  
  // Buttons
  btnDeleteAllMyPosts: document.getElementById('btn-delete-all-my-posts'),
  btnCreateFromMyPosts: document.getElementById('btn-create-from-my-posts'),
  
  // Create Post Form
  createForm: document.getElementById('create-post-form'),
  postCategorySelect: document.getElementById('post-category'),
  dynamicFieldsContainer: document.getElementById('dynamic-category-fields'),
  createGpsText: document.getElementById('create-gps-coordinates'),
  btnCancelCreate: document.getElementById('btn-cancel-create'),
  
  // Admin Portal
  adminLoginCard: document.getElementById('admin-login-card'),
  adminDashboardView: document.getElementById('admin-dashboard-view'),
  adminLoginForm: document.getElementById('admin-login-form'),
  adminUserInput: document.getElementById('admin-user-input'),
  adminPassInput: document.getElementById('admin-pass-input'),
  adminWelcomeText: document.getElementById('admin-welcome-text'),
  btnAdminRefresh: document.getElementById('btn-admin-refresh'),
  btnAdminLogout: document.getElementById('btn-admin-logout'),
  
  // Admin Subtabs & Tables
  adminSubtabs: document.querySelectorAll('.admin-subtab'),
  adminTabPanes: document.querySelectorAll('.admin-tab-pane'),
  adminPostsTbody: document.getElementById('admin-posts-tbody'),
  adminUsersTbody: document.getElementById('admin-users-tbody'),
  adminPostsSearch: document.getElementById('admin-posts-search'),
  adminUsersSearch: document.getElementById('admin-users-search'),
  adminCatFilter: document.getElementById('admin-posts-category-filter'),
  
  // Admin Metrics
  statPosts: document.getElementById('stat-posts'),
  statUsers: document.getElementById('stat-users'),
  statCategories: document.getElementById('stat-categories'),
  statViews: document.getElementById('stat-views'),
  
  // Confirmation Modal
  confirmModal: document.getElementById('confirm-modal'),
  modalTitle: document.getElementById('modal-title'),
  modalSubtitle: document.getElementById('modal-subtitle'),
  modalBody: document.getElementById('modal-body-text'),
  modalBtnCancel: document.getElementById('modal-btn-cancel'),
  modalBtnConfirm: document.getElementById('modal-btn-confirm'),
  
  // API Config Modal
  apiModal: document.getElementById('api-modal'),
  apiUrlInput: document.getElementById('api-url-input'),
  apiModalCancel: document.getElementById('api-modal-cancel'),
  apiModalSave: document.getElementById('api-modal-save'),
  btnSetLocal: document.getElementById('btn-set-local'),
  btnSetRender: document.getElementById('btn-set-render'),
  
  // Toast Hub
  toastHub: document.getElementById('toast-hub'),
};

// ==========================================
// Initialization
// ==========================================
document.addEventListener('DOMContentLoaded', async () => {
  initGeolocation();
  bindEvents();
  await checkBackendStatus();
  await loadCategories();
  await loadFeedPosts();
  await loadMyPosts();
  updateSavedBadge();
  
  if (STATE.adminToken) {
    showAdminDashboard();
  }
});

// ==========================================
// Geolocation & Spatial Distance
// ==========================================
function initGeolocation() {
  if ('geolocation' in navigator) {
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        STATE.userLocation.lat = pos.coords.latitude;
        STATE.userLocation.lng = pos.coords.longitude;
        DOM.gpsText.textContent = `${pos.coords.latitude.toFixed(4)}, ${pos.coords.longitude.toFixed(4)}`;
        if (DOM.createGpsText) {
          DOM.createGpsText.textContent = `Coordinates: ${pos.coords.latitude.toFixed(4)}° N, ${pos.coords.longitude.toFixed(4)}° E (Device GPS)`;
        }
        recalculateDistances();
      },
      () => {
        DOM.gpsText.textContent = 'Dhaka (GPS Default)';
      },
      { timeout: 8000 }
    );
  } else {
    DOM.gpsText.textContent = 'Dhaka (Default)';
  }
}

function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return (R * c).toFixed(1);
}

function recalculateDistances() {
  STATE.posts.forEach(p => {
    p.distance_km = calculateDistance(STATE.userLocation.lat, STATE.userLocation.lng, p.latitude, p.longitude);
  });
  renderFeed();
}

// ==========================================
// Backend Health Check & Auth
// ==========================================
async function checkBackendStatus() {
  // If on HTTPS and apiBase is http://, auto-upgrade to Render live URL
  if (window.location.protocol === 'https:' && STATE.apiBase.startsWith('http://')) {
    STATE.apiBase = RENDER_PROD_API;
    localStorage.setItem('signboard_api_base', RENDER_PROD_API);
  }

  try {
    const res = await fetch(`${STATE.apiBase}/categories/`, { signal: AbortSignal.timeout(8000) });
    if (res.ok) {
      STATE.isBackendLive = true;
      DOM.apiDot.className = 'status-indicator live';
      DOM.apiLabel.textContent = STATE.apiBase.includes('localhost') || STATE.apiBase.includes('127.0.0.1')
        ? 'Backend: Live (Local)'
        : 'Backend: Live (Render Cloud)';
      return true;
    }
  } catch (err) {
    console.warn('Backend not reachable at:', STATE.apiBase, err);
  }
  
  // Fallback to Render cloud if local failed
  if (!STATE.apiBase.includes('onrender.com')) {
    try {
      const res = await fetch(`${RENDER_PROD_API}/categories/`, { signal: AbortSignal.timeout(8000) });
      if (res.ok) {
        STATE.apiBase = RENDER_PROD_API;
        localStorage.setItem('signboard_api_base', RENDER_PROD_API);
        STATE.isBackendLive = true;
        DOM.apiDot.className = 'status-indicator live';
        DOM.apiLabel.textContent = 'Backend: Live (Render Cloud)';
        return true;
      }
    } catch (_) {}
  }
  
  STATE.isBackendLive = false;
  DOM.apiDot.className = 'status-indicator';
  DOM.apiLabel.textContent = 'Backend: Offline (Demo Mode)';
  return false;
}

// Ensure demo user auth token exists
async function ensureAuthToken() {
  if (STATE.authToken) return STATE.authToken;
  try {
    const res = await fetch(`${STATE.apiBase}/auth/google/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'maya.j@example.com',
        name: 'Maya Johnson',
        google_id: 'demo_guest_user',
      })
    });
    if (res.ok) {
      const data = await res.json();
      STATE.authToken = data.token;
      localStorage.setItem('signboard_auth_token', data.token);
      return data.token;
    }
  } catch (e) {
    console.warn('Auth fallback to demo token');
  }
  return 'demo_token';
}

// ==========================================
// Category Loading & Rendering
// ==========================================
async function loadCategories() {
  if (STATE.isBackendLive) {
    try {
      const res = await fetch(`${STATE.apiBase}/categories/`);
      if (res.ok) {
        STATE.categories = await res.json();
      }
    } catch (_) {}
  }
  
  if (!STATE.categories || STATE.categories.length === 0) {
    // High-fidelity fallback categories matching schema
    STATE.categories = [
      { id: 'tutoring', name: 'Tutoring', icon: 'school' },
      { id: 'teachers', name: 'Teachers', icon: 'person_outline' },
      { id: 'used-products', name: 'Used Products', icon: 'shopping_bag' },
      { id: 'self-services', name: 'Self Services', icon: 'build' },
      { id: 'plumbing', name: 'Plumbing', icon: 'plumbing' },
      { id: 'sell-house', name: 'Sell House', icon: 'home' },
      { id: 'sell-property', name: 'Sell Property', icon: 'terrain' },
      { id: 'rent-rooms', name: 'Rent Rooms', icon: 'hotel' },
      { id: 'rent-garage', name: 'Rent Garage', icon: 'garage' },
      { id: 'car-rental', name: 'Car Rental', icon: 'directions_car' },
      { id: 'homemade-food', name: 'Homemade Food', icon: 'restaurant' },
      { id: 'matrimonial', name: 'Matrimonial services', icon: 'favorite' },
      { id: 'others', name: 'Others', icon: 'more_horiz' },
    ];
  }
  
  renderCategoryPills();
  renderCategoryDropdowns();
}

function renderCategoryPills() {
  DOM.catContainer.innerHTML = `
    <button class="cat-pill ${STATE.selectedCategory === 'all' ? 'active' : ''}" data-cat="all" id="cat-pill-all">
      <span class="material-symbols-rounded">grid_view</span>
      <span>All Categories</span>
    </button>
  `;
  
  STATE.categories.forEach(cat => {
    const btn = document.createElement('button');
    btn.className = `cat-pill ${STATE.selectedCategory === cat.id ? 'active' : ''}`;
    btn.dataset.cat = cat.id;
    btn.id = `cat-pill-${cat.id}`;
    btn.innerHTML = `
      <span class="material-symbols-rounded">${cat.icon || 'category'}</span>
      <span>${cat.name}</span>
    `;
    btn.addEventListener('click', () => {
      document.querySelectorAll('.cat-pill').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      STATE.selectedCategory = cat.id;
      filterAndRenderFeed();
    });
    DOM.catContainer.appendChild(btn);
  });
  
  document.getElementById('cat-pill-all').addEventListener('click', () => {
    document.querySelectorAll('.cat-pill').forEach(b => b.classList.remove('active'));
    document.getElementById('cat-pill-all').classList.add('active');
    STATE.selectedCategory = 'all';
    filterAndRenderFeed();
  });
}

function renderCategoryDropdowns() {
  // For Create Post Form
  DOM.postCategorySelect.innerHTML = '<option value="">-- Choose Category --</option>';
  // For Admin Filter
  DOM.adminCatFilter.innerHTML = '<option value="">All Categories</option>';
  
  STATE.categories.forEach(cat => {
    DOM.postCategorySelect.innerHTML += `<option value="${cat.id}">${cat.name}</option>`;
    DOM.adminCatFilter.innerHTML += `<option value="${cat.id}">${cat.name}</option>`;
  });
}

// ==========================================
// Posts Fetching & Rendering
// ==========================================
async function loadFeedPosts() {
  if (STATE.isBackendLive) {
    try {
      const url = `${STATE.apiBase}/posts/?latitude=${STATE.userLocation.lat}&longitude=${STATE.userLocation.lng}`;
      const res = await fetch(url);
      if (res.ok) {
        const data = await res.json();
        STATE.posts = (data.results || data).map(p => ({
          ...p,
          distance_km: p.distance_km || calculateDistance(STATE.userLocation.lat, STATE.userLocation.lng, p.latitude, p.longitude),
        }));
        filterAndRenderFeed();
        return;
      }
    } catch (e) {
      console.warn('Failed to load feed from live backend:', e);
    }
  }
  
  // Seed fallback
  generateDemoPosts();
  filterAndRenderFeed();
}

function generateDemoPosts() {
  STATE.posts = [
    {
      id: 'demo-1',
      title: 'HSC & SSC Higher Math & Physics Home Tutor',
      description: 'Experienced faculty member offering tailored conceptual guidance with weekly exam evaluations and mock tests.',
      category_name: 'Tutoring',
      category_id: 'tutoring',
      contact_whatsapp: '+8801711223344',
      structured_data: { subject: 'Higher Math', student_level: 'Class 9-12', monthly_fee: '8000', days_per_week: '3 Days' },
      latitude: 23.7538,
      longitude: 90.3776,
      address: 'Dhanmondi Road 27, Dhaka',
      city: 'Dhaka',
      distance_km: '0.4',
      views_count: 142,
    },
    {
      id: 'demo-2',
      title: 'Fully Furnished Master Bedroom with Attached Bath & Balcony',
      description: 'Cozy, quiet room with high-speed fiber internet, generator backup, filtered drinking water, and lift.',
      category_name: 'Rent Rooms',
      category_id: 'rent-rooms',
      contact_whatsapp: '+8801812345678',
      structured_data: { room_type: 'Master Bed Room', monthly_rent: '320', floor_no: '4th Floor (With Lift)', available_from: '1st of Next Month' },
      latitude: 23.7946,
      longitude: 90.4143,
      address: 'Gulshan-2 Circle, Dhaka',
      city: 'Dhaka',
      distance_km: '2.8',
      views_count: 219,
    },
    {
      id: 'demo-3',
      title: 'Inverter AC Deep Jet Washing & Gas Refilling Service',
      description: 'Certified technician equipped with high-pressure washing equipment. Transparent pricing and 30 days guarantee.',
      category_name: 'Self Services',
      category_id: 'self-services',
      contact_whatsapp: '+8801911445566',
      structured_data: { service_name: 'AC Jet Wash & Gas Topup', pricing_model: 'Job-based Quotation', availability: '24/7 Emergency' },
      latitude: 23.8072,
      longitude: 90.3686,
      address: 'Mirpur 10 Roundabout, Dhaka',
      city: 'Dhaka',
      distance_km: '3.1',
      views_count: 98,
    },
  ];
}

function filterAndRenderFeed() {
  let list = [...STATE.posts];
  
  if (STATE.selectedCategory !== 'all') {
    list = list.filter(p => p.category_id === STATE.selectedCategory);
  }
  
  if (STATE.searchQuery.trim()) {
    const q = STATE.searchQuery.toLowerCase();
    list = list.filter(p => 
      p.title.toLowerCase().includes(q) ||
      (p.description && p.description.toLowerCase().includes(q)) ||
      (p.category_name && p.category_name.toLowerCase().includes(q)) ||
      (p.address && p.address.toLowerCase().includes(q))
    );
  }
  
  if (STATE.sortBy === 'distance') {
    list.sort((a, b) => parseFloat(a.distance_km || 999) - parseFloat(b.distance_km || 999));
  } else if (STATE.sortBy === 'views') {
    list.sort((a, b) => (b.views_count || 0) - (a.views_count || 0));
  }
  
  renderCards(list, DOM.postsContainer);
}

function renderCards(postsList, targetElement, isMyPosts = false) {
  if (!postsList || postsList.length === 0) {
    targetElement.innerHTML = `
      <div style="grid-column: 1 / -1; text-align: center; padding: 48px 16px;">
        <span class="material-symbols-rounded" style="font-size: 52px; color: var(--text-muted); margin-bottom: 12px;">search_off</span>
        <h3 style="font-size: 1.1rem; font-weight: 700; color: var(--primary-dark); margin-bottom: 6px;">No Signboards Found</h3>
        <p style="font-size: 0.88rem; color: var(--text-secondary);">Try changing your search term or select a different category above.</p>
      </div>
    `;
    return;
  }
  
  targetElement.innerHTML = '';
  postsList.forEach(post => {
    const isSaved = STATE.savedPosts.includes(post.id);
    const card = document.createElement('article');
    card.className = 'signboard-card';
    card.id = `card-${post.id}`;
    
    // Build Structured Attributes HTML
    let attrsHtml = '';
    if (post.structured_data && typeof post.structured_data === 'object') {
      for (const [k, v] of Object.entries(post.structured_data)) {
        if (v) {
          const label = k.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
          attrsHtml += `<span class="attribute-tag"><strong>${label}:</strong> ${v}</span>`;
        }
      }
    }
    
    // Clean WhatsApp number
    const rawPhone = (post.contact_whatsapp || '+8801711223344').replace(/[^0-9]/g, '');
    const waText = encodeURIComponent(`Hi, I saw your SignBoard post: "${post.title}" and would like more details.`);
    const waUrl = `https://wa.me/${rawPhone}?text=${waText}`;
    const mapUrl = `https://www.google.com/maps/dir/?api=1&destination=${post.latitude},${post.longitude}`;
    
    card.innerHTML = `
      <div class="card-top">
        <div class="card-category-row">
          <span class="card-category-name">${post.category_name || 'Category'}</span>
          <span class="card-distance-badge">• ${post.distance_km ? `${post.distance_km} km away` : 'Nearby'}</span>
        </div>
        <div class="card-top-actions">
          ${isMyPosts ? `
            <button class="icon-btn delete-icon" title="Delete post" data-delete-id="${post.id}">
              <span class="material-symbols-rounded">delete_outline</span>
            </button>
          ` : ''}
          <button class="icon-btn ${isSaved ? 'bookmarked' : ''}" title="Bookmark" data-save-id="${post.id}">
            <span class="material-symbols-rounded">${isSaved ? 'bookmark' : 'bookmark_border'}</span>
          </button>
        </div>
      </div>

      <h3 class="card-title">${escapeHtml(post.title)}</h3>

      ${attrsHtml ? `<div class="card-attributes">${attrsHtml}</div>` : ''}

      <p class="card-description">${escapeHtml(post.description || 'Verified local classified signboard.')}</p>

      <div class="card-location-meta">
        <span class="material-symbols-rounded">location_on</span>
        <span>${escapeHtml(post.address || post.city || 'Dhaka')}</span>
      </div>

      <div class="card-actions-grid">
        <a href="${waUrl}" target="_blank" rel="noopener noreferrer" class="whatsapp-action-btn">
          <span class="material-symbols-rounded">chat</span>
          <span>WhatsApp</span>
        </a>
        <a href="${mapUrl}" target="_blank" rel="noopener noreferrer" class="goroute-action-btn">
          <span class="material-symbols-rounded">directions</span>
          <span>Go Route</span>
        </a>
      </div>
    `;
    
    // Attach Bookmark Click
    card.querySelector(`[data-save-id="${post.id}"]`).addEventListener('click', (e) => {
      e.stopPropagation();
      toggleSavePost(post);
    });
    
    // Attach Delete Click (if My Posts)
    if (isMyPosts) {
      card.querySelector(`[data-delete-id="${post.id}"]`).addEventListener('click', (e) => {
        e.stopPropagation();
        confirmDeleteSinglePost(post);
      });
    }
    
    targetElement.appendChild(card);
  });
}

// ==========================================
// Bookmarks / Saved Posts
// ==========================================
function toggleSavePost(post) {
  const idx = STATE.savedPosts.indexOf(post.id);
  if (idx > -1) {
    STATE.savedPosts.splice(idx, 1);
    showToast('Removed from bookmarks');
  } else {
    STATE.savedPosts.push(post.id);
    showToast('Saved to your bookmarks!', 'success');
  }
  
  localStorage.setItem('signboard_saved_ids', JSON.stringify(STATE.savedPosts));
  updateSavedBadge();
  filterAndRenderFeed();
  renderSavedView();
}

function updateSavedBadge() {
  DOM.savedCounter.textContent = STATE.savedPosts.length;
}

function renderSavedView() {
  const savedList = STATE.posts.filter(p => STATE.savedPosts.includes(p.id));
  renderCards(savedList, DOM.savedContainer);
}

// ==========================================
// User "My Posts" (Delete One-by-One & Delete All)
// ==========================================
async function loadMyPosts() {
  if (STATE.isBackendLive) {
    try {
      const token = await ensureAuthToken();
      const res = await fetch(`${STATE.apiBase}/posts/my/`, {
        headers: { 'Authorization': `Token ${token}` }
      });
      if (res.ok) {
        const data = await res.json();
        STATE.myPosts = data.results || data;
        renderMyPostsView();
        return;
      }
    } catch (_) {}
  }
  
  // Local storage cache or demo
  const localMy = JSON.parse(localStorage.getItem('signboard_my_posts') || '[]');
  STATE.myPosts = localMy.length > 0 ? localMy : (STATE.posts.slice(0, 2));
  renderMyPostsView();
}

function renderMyPostsView() {
  DOM.myPostsCounter.textContent = STATE.myPosts.length;
  renderCards(STATE.myPosts, DOM.myPostsContainer, true);
}

// 1. Delete One-by-One
function confirmDeleteSinglePost(post) {
  openConfirmModal({
    title: 'Delete Signboard Post?',
    subtitle: 'This will permanently remove this listing from the platform.',
    bodyText: `Are you sure you want to delete "<strong>${escapeHtml(post.title)}</strong>"? This action cannot be reversed.`,
    confirmText: 'Delete Post',
    onConfirm: async () => {
      await executeDeleteSinglePost(post);
    }
  });
}

async function executeDeleteSinglePost(post) {
  if (STATE.isBackendLive) {
    try {
      const token = await ensureAuthToken();
      const res = await fetch(`${STATE.apiBase}/posts/${post.id}/`, {
        method: 'DELETE',
        headers: { 'Authorization': `Token ${token}` }
      });
      if (!res.ok && res.status !== 204) {
        throw new Error('Server returned error');
      }
    } catch (err) {
      console.warn('Backend delete post error:', err);
    }
  }
  
  // Update local state
  STATE.myPosts = STATE.myPosts.filter(p => p.id !== post.id);
  STATE.posts = STATE.posts.filter(p => p.id !== post.id);
  localStorage.setItem('signboard_my_posts', JSON.stringify(STATE.myPosts));
  
  renderMyPostsView();
  filterAndRenderFeed();
  showToast('Post deleted successfully');
}

// 2. Delete All Posts
DOM.btnDeleteAllMyPosts.addEventListener('click', () => {
  if (STATE.myPosts.length === 0) {
    showToast('You have no active posts to delete', 'error');
    return;
  }
  
  openConfirmModal({
    title: 'Delete All My Posts?',
    subtitle: 'Mass deletion confirmation',
    bodyText: `You are about to permanently delete <strong>all ${STATE.myPosts.length} posts</strong> from your account. This action cannot be undone.<br><br>Are you completely sure?`,
    confirmText: 'Delete All Posts',
    onConfirm: async () => {
      await executeDeleteAllMyPosts();
    }
  });
});

async function executeDeleteAllMyPosts() {
  if (STATE.isBackendLive) {
    try {
      const token = await ensureAuthToken();
      const res = await fetch(`${STATE.apiBase}/posts/my/delete-all/`, {
        method: 'DELETE',
        headers: { 'Authorization': `Token ${token}` }
      });
      if (!res.ok && res.status !== 204) {
        throw new Error('Server returned error');
      }
    } catch (err) {
      console.warn('Backend delete all error:', err);
    }
  }
  
  const count = STATE.myPosts.length;
  STATE.myPosts = [];
  localStorage.setItem('signboard_my_posts', JSON.stringify([]));
  
  renderMyPostsView();
  filterAndRenderFeed();
  showToast(`Successfully deleted all ${count} posts!`);
}

// Category Templates for Dynamic Headlines & Formal Detailed Descriptions
const CATEGORY_TEMPLATES = {
  'tutoring': {
    title: 'e.g. HSC & SSC Higher Math & Physics Home Tutor in Dhanmondi',
    desc: 'Experienced faculty member offering tailored conceptual guidance with weekly exam evaluations and mock tests.\n\n• Target Classes: Class 9 - 12 (SSC/HSC & O/A Level)\n• Subjects: Higher Mathematics, Physics, Chemistry\n• Schedule: 3 Days/week (1.5 hours per session)\n• Honorarium: Tk 8,000 - 12,000/month',
  },
  'teachers': {
    title: 'e.g. Senior Lecturer in Mathematics - 10+ Years College Teaching Experience',
    desc: 'M.Sc in Applied Mathematics with over 10 years of institutional college teaching experience. Offering specialized advanced coaching for board exams and admissions.\n\n• Highest Degree: M.Sc in Mathematics (DU)\n• Availability: Weekend masterclasses & evening 1-on-1 mentorship\n• Rate: Tk 1,500/hour or Tk 15,000/month',
  },
  'used-products': {
    title: 'e.g. Apple MacBook Air M2 16GB/512GB (Space Gray, Like New with Box)',
    desc: 'Authentic Apple MacBook Air M2 in pristine, scratchless condition with original 35W dual USB-C charger, box, and purchase memo.\n\n• Specifications: Apple M2 chip, 16GB Unified RAM, 512GB SSD\n• Battery Health: 94% (112 Cycles)\n• Price: Tk 1,18,000 (Slightly negotiable for real buyers)\n• Pick-up Location: Gulshan 2, Dhaka',
  },
  'self-services': {
    title: 'e.g. Professional Inverter AC Deep Jet Wash & Gas Top-Up Service',
    desc: 'Certified refrigeration technicians equipped with high-pressure water jet pumps, manifold gauges, and genuine refrigerant gas.\n\n• Services Included: Indoor & outdoor unit jet wash, blower cleaning, drain tray unclogging\n• Guarantee: 30-day service warranty against gas leakage\n• Inspection Fee: Tk 300\n• Availability: 24/7 doorstep service across Dhaka',
  },
  'plumbing': {
    title: 'e.g. Emergency Concealed Pipe Leakage Detection & Sanitary Repair',
    desc: 'Master plumber with 12+ years experience in multi-storied residential complexes and modern sanitary installations.\n\n• Specialization: Concealed acoustic leak detection, PPR pipe joint welding, geyser installation\n• Response Time: Within 45 minutes across Dhaka\n• Warranty: 90 days work guarantee on all pipe fittings',
  },
  'sell-house': {
    title: 'e.g. 2150 Sq Ft Luxurious South Facing 3-BHK Apartment with 2 Car Parks',
    desc: 'Brand new ready apartment on the 6th floor with expansive south-facing cross ventilation and double balconies.\n\n• Accommodations: 3 Master Bedrooms, 4 Bathrooms, Large Drawing & Dining, Servant Suite\n• Building Amenities: Double high-speed lifts, generator backup, 24/7 CCTV & security guards\n• Land Share & Papers: Clear mutation, registered deed, Rajuk approved plan\n• Asking Price: Tk 1,85,00,000 (Negotiable)',
  },
  'sell-property': {
    title: 'e.g. 5 Katha Prime Commercial Corner Plot Facing 60 Ft Wide Road',
    desc: 'High-value commercial freehold land located directly on the 60-feet wide main avenue with immense commercial potential.\n\n• Size: 5 Katha (approx. 3,600 sq ft)\n• Boundary: Demarcated RCC boundary wall with security gate\n• Utilities: Electricity line and gas supply connection available adjacent to plot\n• Documentation: CS, SA, RS, BS all Khatians updated with paid tax up to current fiscal year',
  },
  'rent-rooms': {
    title: 'e.g. Fully Furnished Master Bedroom with Attached Bath & Balcony for Rent',
    desc: 'Spacious, well-ventilated master bedroom available in a modern 4th floor family apartment.\n\n• Facilities: Attached high-commode bathroom, private south balcony, ceiling fan\n• Inclusions: High-speed fiber WiFi, generator backup, filtered drinking water\n• Rent: Tk 12,000/month (Including utility and service charge)\n• Suitable For: Working executive or university student',
  },
  'rent-garage': {
    title: 'e.g. Dedicated Covered Garage Space for Large SUV in Gated Apartment',
    desc: 'Secure ground floor covered parking bay suitable for large SUVs (Prado, Harrier) or sedans.\n\n• Security: 24/7 CCTV surveillance, gatekeeper guard on duty, automated sliding shutter\n• Facilities: Water hose connection for daily car washing, bright night lighting\n• Monthly Rent: Tk 4,500/month (Advance 1 month)',
  },
  'car-rental': {
    title: 'e.g. Toyota Allion / Premio 2022 with Experienced Driver for Intercity Trips',
    desc: 'Premium chauffeur-driven sedan available for daily city rent, airport transfers, weddings, and outstation tours.\n\n• Vehicle Model: Toyota Allion 2022 (Pearl White, Super Cool Dual AC)\n• Chauffeur: Courteous, verified driver with 8+ years highway experience\n• Daily City Rate: Tk 3,500 (10 hours body rent, fuel & toll excluded)\n• Booking: Please confirm 24 hours prior via WhatsApp',
  },
  'homemade-food': {
    title: 'e.g. Traditional Kacchi Biryani & Daily Diet Lunch Box Subscription',
    desc: 'Hygienic, mouth-watering home-cooked meals prepared with premium Basmati rice, farm-fresh mutton, and zero artificial colors.\n\n• Daily Office Lunch Box: Rice, 2 Bhortas, Thick Dal, and Choice of Chicken or Rui Fish Curry (Tk 160/meal)\n• Weekend Specials: Mutton Kacchi Biryani with Borhani (Tk 380/platter)\n• Monthly Packages: 26-day lunch subscription with free insulated box delivery',
  },
  'matrimonial': {
    title: 'e.g. Looking for Educated & Religious Groom for Software Engineer Bride (26)',
    desc: 'Respectable Suni Muslim family seeking a well-educated, gentle, and established groom for their daughter.\n\n• Bride Profile: 26 years, 5\'4", B.Sc in CSE from leading university, Senior Software Engineer\n• Looking For: 27-31 years, Minimum B.Sc / Masters, well-settled in Dhaka or abroad\n• Contact: Direct WhatsApp communication with parents',
  },
  'others': {
    title: 'e.g. Professional Legal Documentation, Land Mutation & Registration Assistance',
    desc: 'Advocate and legal consultancy service helping clients with fast, hassle-free land mutation, registry vetting, and deed drafts.\n\n• Services: Land registry deed verification, Porcha/Khatian collection, municipal tax updates\n• Fees: Transparent fixed-charge per service\n• Office: Purana Paltan / Dhaka Judge Court',
  },
};

// ==========================================
// Post Creation
// ==========================================
function updateCreateFormCategoryTemplates(catId) {
  const cat = STATE.categories.find(c => c.id === catId);
  const tmpl = CATEGORY_TEMPLATES[catId] || CATEGORY_TEMPLATES['others'];
  
  const titleLabel = document.getElementById('post-title-label');
  const titleInput = document.getElementById('post-title');
  const titleHint = document.getElementById('post-title-hint');
  const descInput = document.getElementById('post-desc');
  const exampleName = document.getElementById('example-desc-cat-name');
  const examplePreview = document.getElementById('example-desc-preview');
  
  if (titleLabel) titleLabel.textContent = `Signboard Title * (${cat ? cat.name : 'Category'})`;
  if (titleInput) titleInput.placeholder = tmpl.title;
  if (titleHint) titleHint.textContent = `Recommended format: ${tmpl.title}`;
  if (descInput) descInput.placeholder = tmpl.desc;
  if (exampleName) exampleName.textContent = `Formal Example for ${cat ? cat.name : 'Selected Category'}:`;
  if (examplePreview) examplePreview.textContent = tmpl.desc;
}

DOM.postCategorySelect.addEventListener('change', () => {
  const catId = DOM.postCategorySelect.value;
  renderDynamicCategoryFields(catId);
  updateCreateFormCategoryTemplates(catId);
});

// Button: Insert Example Template directly into description textarea
const btnUseExampleDesc = document.getElementById('btn-use-example-desc');
if (btnUseExampleDesc) {
  btnUseExampleDesc.addEventListener('click', () => {
    const catId = DOM.postCategorySelect.value || 'others';
    const tmpl = CATEGORY_TEMPLATES[catId] || CATEGORY_TEMPLATES['others'];
    const descInput = document.getElementById('post-desc');
    if (descInput) {
      descInput.value = tmpl.desc;
      showToast('Example template inserted into description!', 'info');
    }
  });
}

// Button: Refresh My Posts
const btnRefreshMyPosts = document.getElementById('btn-refresh-my-posts');
if (btnRefreshMyPosts) {
  btnRefreshMyPosts.addEventListener('click', async () => {
    await loadMyPosts();
    showToast('My posts refreshed successfully!', 'success');
  });
}

function renderDynamicCategoryFields(catId) {
  const cat = STATE.categories.find(c => c.id === catId);
  if (!cat || !cat.fields_schema || cat.fields_schema.length === 0) {
    DOM.dynamicFieldsContainer.innerHTML = '';
    return;
  }
  
  DOM.dynamicFieldsContainer.innerHTML = '';
  cat.fields_schema.forEach(f => {
    const group = document.createElement('div');
    group.className = 'form-group';
    
    let inputHtml = '';
    if (f.type === 'select' && f.options) {
      const opts = f.options.map(o => `<option value="${o}">${o}</option>`).join('');
      inputHtml = `
        <select id="field-${f.id}" name="${f.id}" class="custom-select" ${f.required ? 'required' : ''}>
          <option value="">Select ${f.label}</option>
          ${opts}
        </select>
      `;
    } else {
      inputHtml = `
        <input type="${f.type === 'number' ? 'number' : 'text'}" id="field-${f.id}" name="${f.id}" class="form-input" placeholder="${f.placeholder || f.label}" ${f.required ? 'required' : ''}>
      `;
    }
    
    group.innerHTML = `
      <label class="form-label">${f.label} ${f.required ? '*' : ''}</label>
      ${inputHtml}
    `;
    DOM.dynamicFieldsContainer.appendChild(group);
  });
}

DOM.createForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  
  const catId = DOM.postCategorySelect.value;
  const title = document.getElementById('post-title').value.trim();
  const whatsapp = document.getElementById('post-whatsapp').value.trim();
  const desc = document.getElementById('post-desc').value.trim();
  const city = document.getElementById('post-city').value.trim();
  const address = document.getElementById('post-address').value.trim();
  
  // Extract dynamic fields
  const structData = {};
  const cat = STATE.categories.find(c => c.id === catId);
  if (cat && cat.fields_schema) {
    cat.fields_schema.forEach(f => {
      const el = document.getElementById(`field-${f.id}`);
      if (el && el.value) {
        structData[f.id] = el.value;
      }
    });
  }
  
  const newPostPayload = {
    category: catId,
    title,
    description: desc,
    contact_whatsapp: whatsapp,
    structured_data: structData,
    latitude: STATE.userLocation.lat,
    longitude: STATE.userLocation.lng,
    city: city || 'Dhaka',
    address: address || `${city || 'Dhaka'}`,
  };
  
  let createdPost = null;
  if (STATE.isBackendLive) {
    try {
      const token = await ensureAuthToken();
      const res = await fetch(`${STATE.apiBase}/posts/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Token ${token}`
        },
        body: JSON.stringify(newPostPayload),
      });
      if (res.ok) {
        createdPost = await res.json();
      }
    } catch (err) {
      console.warn('Live create post failed:', err);
    }
  }
  
  if (!createdPost) {
    // Local fallback
    createdPost = {
      ...newPostPayload,
      id: `local-${Date.now()}`,
      category_name: cat ? cat.name : 'Classified',
      category_id: catId,
      views_count: 1,
      distance_km: '0.1',
      created_at: new Date().toISOString(),
    };
  }
  
  // Add to user posts and general feed immediately
  STATE.myPosts.unshift(createdPost);
  STATE.posts.unshift(createdPost);
  localStorage.setItem('signboard_my_posts', JSON.stringify(STATE.myPosts));
  
  // 1. Clear ALL fields and reset form state
  DOM.createForm.reset();
  DOM.dynamicFieldsContainer.innerHTML = '';
  updateCreateFormCategoryTemplates('');
  
  showToast('SignBoard post published successfully! All fields cleared.', 'success');
  
  // 2. Re-render My Posts view and switch tab instantly
  renderMyPostsView();
  filterAndRenderFeed();
  switchTab('my-posts');
});


// ==========================================
// Professional Admin Dashboard
// ==========================================
DOM.adminLoginForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  const username = DOM.adminUserInput.value.trim();
  const password = DOM.adminPassInput.value.trim();
  
  if (STATE.isBackendLive) {
    try {
      const res = await fetch(`${STATE.apiBase}/admin/login/`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
      });
      if (res.ok) {
        const data = await res.json();
        STATE.adminToken = data.token;
        STATE.adminUser = data.user;
        localStorage.setItem('signboard_admin_token', data.token);
        localStorage.setItem('signboard_admin_user', JSON.stringify(data.user));
        showAdminDashboard();
        showToast('Authenticated as Administrator!', 'success');
        return;
      } else {
        const err = await res.json();
        showToast(err.detail || 'Invalid admin credentials', 'error');
        return;
      }
    } catch (_) {}
  }
  
  // Fallback demo admin credentials
  if ((username === 'admin' || username === 'admin@signboard.com') && (password === 'adminpassword123' || password === 'admin')) {
    STATE.adminToken = 'mock_admin_token';
    STATE.adminUser = { username: 'admin', is_staff: true, is_superuser: true };
    localStorage.setItem('signboard_admin_token', 'mock_admin_token');
    showAdminDashboard();
    showToast('Admin authenticated (Demo Mode)', 'success');
  } else {
    showToast('Invalid admin credentials', 'error');
  }
});

function showAdminDashboard() {
  DOM.adminLoginCard.style.display = 'none';
  DOM.adminDashboardView.style.display = 'block';
  DOM.adminWelcomeText.textContent = `Logged in as ${STATE.adminUser?.username || 'admin'} (Superuser)`;
  loadAdminStats();
  loadAdminPosts();
  loadAdminUsers();
}

DOM.btnAdminLogout.addEventListener('click', () => {
  STATE.adminToken = '';
  STATE.adminUser = null;
  localStorage.removeItem('signboard_admin_token');
  localStorage.removeItem('signboard_admin_user');
  DOM.adminDashboardView.style.display = 'none';
  DOM.adminLoginCard.style.display = 'block';
  showToast('Logged out of admin console');
});

DOM.btnAdminRefresh.addEventListener('click', () => {
  loadAdminStats();
  loadAdminPosts();
  loadAdminUsers();
  showToast('Admin metrics refreshed');
});

// Admin Subtabs switching
DOM.adminSubtabs.forEach(tab => {
  tab.addEventListener('click', () => {
    DOM.adminSubtabs.forEach(t => t.classList.remove('active'));
    DOM.adminTabPanes.forEach(p => p.classList.remove('active'));
    
    tab.classList.add('active');
    const targetPane = document.getElementById(`admin-pane-${tab.dataset.subtab}`);
    if (targetPane) targetPane.classList.add('active');
  });
});

async function loadAdminStats() {
  if (STATE.isBackendLive && STATE.adminToken) {
    try {
      const res = await fetch(`${STATE.apiBase}/admin/stats/`, {
        headers: { 'Authorization': `Token ${STATE.adminToken}` }
      });
      if (res.ok) {
        const stats = await res.json();
        DOM.statPosts.textContent = stats.total_posts.toLocaleString();
        DOM.statUsers.textContent = stats.total_users.toLocaleString();
        DOM.statCategories.textContent = stats.categories.length;
        DOM.statViews.textContent = stats.total_views.toLocaleString();
        return;
      }
    } catch (_) {}
  }
  
  // Default values
  DOM.statPosts.textContent = STATE.posts.length > 5 ? STATE.posts.length.toLocaleString() : '13,000+';
  DOM.statUsers.textContent = '12';
  DOM.statCategories.textContent = '13';
  DOM.statViews.textContent = '24,850';
}

// Admin: All Posts Moderation Table
async function loadAdminPosts() {
  let postsData = [];
  const search = DOM.adminPostsSearch.value.trim();
  const cat = DOM.adminCatFilter.value;
  
  if (STATE.isBackendLive && STATE.adminToken) {
    try {
      const res = await fetch(`${STATE.apiBase}/admin/posts/?search=${encodeURIComponent(search)}&category=${encodeURIComponent(cat)}`, {
        headers: { 'Authorization': `Token ${STATE.adminToken}` }
      });
      if (res.ok) {
        const data = await res.json();
        postsData = data.posts || [];
      }
    } catch (_) {}
  }
  
  if (postsData.length === 0) {
    postsData = STATE.posts.slice(0, 30);
  }
  
  DOM.adminPostsTbody.innerHTML = '';
  postsData.forEach(p => {
    const tr = document.createElement('tr');
    tr.id = `admin-row-post-${p.id}`;
    tr.innerHTML = `
      <td>
        <strong style="color: var(--primary-dark); font-size: 0.9rem;">${escapeHtml(p.title)}</strong><br>
        <span style="font-size: 0.78rem; color: var(--text-muted);">${escapeHtml(p.address || p.city || 'Dhaka')}</span>
      </td>
      <td><span class="tag-badge tag-user">${escapeHtml(p.category_name || 'Listing')}</span></td>
      <td>${escapeHtml(p.user_name || 'User')}</td>
      <td><code>${escapeHtml(p.contact_whatsapp || 'N/A')}</code></td>
      <td>${p.views_count || 0}</td>
      <td style="color: var(--text-secondary); font-size: 0.8rem;">${p.created_at ? p.created_at.slice(0, 10) : 'Recent'}</td>
      <td style="text-align: right;">
        <button class="danger-outline-btn btn-admin-delete-post" data-id="${p.id}" data-title="${escapeHtml(p.title)}">
          <span class="material-symbols-rounded">delete</span>
          <span>Delete</span>
        </button>
      </td>
    `;
    
    tr.querySelector('.btn-admin-delete-post').addEventListener('click', () => {
      confirmAdminDeletePost(p.id, p.title);
    });
    
    DOM.adminPostsTbody.appendChild(tr);
  });
}

function confirmAdminDeletePost(postId, title) {
  openConfirmModal({
    title: 'Admin: Delete Post?',
    subtitle: 'Moderation action',
    bodyText: `Are you sure you want to permanently delete post "<strong>${escapeHtml(title)}</strong>"?`,
    confirmText: 'Delete Post',
    onConfirm: async () => {
      if (STATE.isBackendLive && STATE.adminToken) {
        try {
          await fetch(`${STATE.apiBase}/admin/posts/${postId}/`, {
            method: 'DELETE',
            headers: { 'Authorization': `Token ${STATE.adminToken}` }
          });
        } catch (_) {}
      }
      
      const row = document.getElementById(`admin-row-post-${postId}`);
      if (row) row.remove();
      
      // Also remove from global state
      STATE.posts = STATE.posts.filter(p => p.id !== postId);
      STATE.myPosts = STATE.myPosts.filter(p => p.id !== postId);
      
      showToast(`Post "${title}" deleted by Admin`, 'success');
      loadAdminStats();
    }
  });
}

// Admin: User Accounts Table
async function loadAdminUsers() {
  let usersData = [];
  const search = DOM.adminUsersSearch.value.trim();
  
  if (STATE.isBackendLive && STATE.adminToken) {
    try {
      const res = await fetch(`${STATE.apiBase}/admin/users/?search=${encodeURIComponent(search)}`, {
        headers: { 'Authorization': `Token ${STATE.adminToken}` }
      });
      if (res.ok) {
        const data = await res.json();
        usersData = data.users || [];
      }
    } catch (_) {}
  }
  
  if (usersData.length === 0) {
    usersData = [
      { id: 'u1', username: 'admin', email: 'admin@signboard.com', name: 'Site Administrator', is_staff: true, posts_count: 0, date_joined: '2026-10-01' },
      { id: 'u2', username: 'maya.j', email: 'maya.j@example.com', name: 'Maya Johnson', is_staff: false, posts_count: 4, date_joined: '2026-10-02' },
      { id: 'u3', username: 'tahmid.h', email: 'tahmid.h@example.com', name: 'Engr. Tahmid Hasan', is_staff: false, posts_count: 12, date_joined: '2026-10-03' },
      { id: 'u4', username: 'sumaiya.a', email: 'sumaiya.a@example.com', name: 'Sumaiya Akter', is_staff: false, posts_count: 8, date_joined: '2026-10-04' },
    ];
  }
  
  DOM.adminUsersTbody.innerHTML = '';
  usersData.forEach(u => {
    const tr = document.createElement('tr');
    tr.id = `admin-row-user-${u.id}`;
    tr.innerHTML = `
      <td>
        <div class="user-cell">
          <img src="${u.avatar_url || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100'}" class="user-avatar-sm" alt="Avatar">
          <div>
            <strong>${escapeHtml(u.name || u.username)}</strong><br>
            <span style="font-size: 0.78rem; color: var(--text-muted);">@${escapeHtml(u.username)}</span>
          </div>
        </div>
      </td>
      <td>${escapeHtml(u.email)}</td>
      <td>
        <span class="tag-badge ${u.is_staff ? 'tag-staff' : 'tag-user'}">
          ${u.is_staff ? 'Staff Admin' : 'Regular User'}
        </span>
      </td>
      <td><strong>${u.posts_count || 0}</strong></td>
      <td style="color: var(--text-secondary); font-size: 0.8rem;">${u.date_joined || 'Recent'}</td>
      <td style="text-align: right;">
        ${u.is_staff ? '<span style="font-size: 0.76rem; color: var(--text-muted);">Protected</span>' : `
          <button class="danger-outline-btn btn-admin-delete-user" data-id="${u.id}" data-name="${escapeHtml(u.name || u.username)}">
            <span class="material-symbols-rounded">person_remove</span>
            <span>Delete User</span>
          </button>
        `}
      </td>
    `;
    
    if (!u.is_staff) {
      tr.querySelector('.btn-admin-delete-user').addEventListener('click', () => {
        confirmAdminDeleteUser(u.id, u.name || u.username);
      });
    }
    
    DOM.adminUsersTbody.appendChild(tr);
  });
}

function confirmAdminDeleteUser(userId, name) {
  openConfirmModal({
    title: 'Admin: Delete User Account?',
    subtitle: 'High Impact Action',
    bodyText: `Are you sure you want to delete user account "<strong>${escapeHtml(name)}</strong>"?<br><br>All signboards and listings published by this user will also be removed immediately.`,
    confirmText: 'Delete User Account',
    onConfirm: async () => {
      if (STATE.isBackendLive && STATE.adminToken) {
        try {
          await fetch(`${STATE.apiBase}/admin/users/${userId}/`, {
            method: 'DELETE',
            headers: { 'Authorization': `Token ${STATE.adminToken}` }
          });
        } catch (_) {}
      }
      
      const row = document.getElementById(`admin-row-user-${userId}`);
      if (row) row.remove();
      
      showToast(`User "${name}" and all posts deleted by Admin`, 'success');
      loadAdminStats();
    }
  });
}

// Search listeners in Admin
DOM.adminPostsSearch.addEventListener('input', debounce(loadAdminPosts, 300));
DOM.adminCatFilter.addEventListener('change', loadAdminPosts);
DOM.adminUsersSearch.addEventListener('input', debounce(loadAdminUsers, 300));

// ==========================================
// Tab Switching
// ==========================================
function bindEvents() {
  // Navigation Tabs
  DOM.navTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      switchTab(tab.dataset.tab);
    });
  });
  
  // Brand Logo Click -> Go Home
  document.getElementById('btn-brand-home').addEventListener('click', () => {
    switchTab('feed');
  });
  
  // Refresh GPS
  DOM.btnRefreshGps.addEventListener('click', () => {
    DOM.gpsText.textContent = 'Locating GPS...';
    initGeolocation();
    showToast('Refreshing GPS coordinates...');
  });
  
  // API Config Modal
  DOM.btnApiConfig.addEventListener('click', () => {
    DOM.apiUrlInput.value = STATE.apiBase;
    DOM.apiModal.style.display = 'flex';
  });
  DOM.apiModalCancel.addEventListener('click', () => {
    DOM.apiModal.style.display = 'none';
  });
  DOM.btnSetLocal.addEventListener('click', () => {
    DOM.apiUrlInput.value = 'http://127.0.0.1:8000/api';
  });
  DOM.btnSetRender.addEventListener('click', () => {
    DOM.apiUrlInput.value = 'https://signboard-backend.onrender.com/api';
  });
  DOM.apiModalSave.addEventListener('click', async () => {
    const newUrl = DOM.apiUrlInput.value.trim().replace(/\/+$/, '');
    if (newUrl) {
      STATE.apiBase = newUrl;
      localStorage.setItem('signboard_api_base', newUrl);
      DOM.apiModal.style.display = 'none';
      showToast(`Connecting to ${newUrl}...`);
      await checkBackendStatus();
      await loadCategories();
      await loadFeedPosts();
    }
  });
  
  // Search
  DOM.searchInput.addEventListener('input', () => {
    STATE.searchQuery = DOM.searchInput.value;
    DOM.btnClearSearch.style.display = STATE.searchQuery ? 'flex' : 'none';
    filterAndRenderFeed();
  });
  DOM.btnClearSearch.addEventListener('click', () => {
    DOM.searchInput.value = '';
    STATE.searchQuery = '';
    DOM.btnClearSearch.style.display = 'none';
    filterAndRenderFeed();
  });
  
  // Sort
  DOM.sortSelect.addEventListener('change', () => {
    STATE.sortBy = DOM.sortSelect.value;
    filterAndRenderFeed();
  });
  
  // Buttons
  DOM.btnCancelCreate.addEventListener('click', () => switchTab('feed'));
  DOM.btnCreateFromMyPosts.addEventListener('click', () => switchTab('create'));
  
  // Confirmation Modal Cancel
  DOM.modalBtnCancel.addEventListener('click', closeConfirmModal);
}

function switchTab(tabId) {
  DOM.navTabs.forEach(t => t.classList.toggle('active', t.dataset.tab === tabId));
  DOM.tabContents.forEach(c => c.classList.toggle('active', c.id === `view-${tabId}`));
  
  // Show discovery bar only on Feed
  DOM.discoveryBar.style.display = (tabId === 'feed') ? 'flex' : 'none';
  
  if (tabId === 'saved') {
    renderSavedView();
  } else if (tabId === 'my-posts') {
    loadMyPosts();
  } else if (tabId === 'admin') {
    if (STATE.adminToken) showAdminDashboard();
  }
  
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// ==========================================
// Reusable Confirmation Modal
// ==========================================
let activeConfirmCallback = null;

function openConfirmModal({ title, subtitle, bodyText, confirmText = 'Delete', onConfirm }) {
  DOM.modalTitle.textContent = title;
  DOM.modalSubtitle.textContent = subtitle;
  DOM.modalBody.innerHTML = bodyText;
  DOM.modalBtnConfirm.textContent = confirmText;
  activeConfirmCallback = onConfirm;
  DOM.confirmModal.style.display = 'flex';
}

function closeConfirmModal() {
  DOM.confirmModal.style.display = 'none';
  activeConfirmCallback = null;
}

DOM.modalBtnConfirm.addEventListener('click', async () => {
  if (activeConfirmCallback) {
    DOM.modalBtnConfirm.disabled = true;
    DOM.modalBtnConfirm.textContent = 'Processing...';
    try {
      await activeConfirmCallback();
    } finally {
      DOM.modalBtnConfirm.disabled = false;
      closeConfirmModal();
    }
  }
});

// ==========================================
// Toast Notifications
// ==========================================
function showToast(message, type = 'info') {
  const toast = document.createElement('div');
  toast.className = `toast ${type === 'error' ? 'toast-error' : type === 'success' ? 'toast-success' : ''}`;
  toast.innerHTML = `
    <span class="material-symbols-rounded">${type === 'error' ? 'error' : type === 'success' ? 'check_circle' : 'info'}</span>
    <span>${escapeHtml(message)}</span>
  `;
  DOM.toastHub.appendChild(toast);
  
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(10px)';
    toast.style.transition = 'all 200ms ease';
    setTimeout(() => toast.remove(), 250);
  }, 3200);
}

// ==========================================
// Utilities
// ==========================================
function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function debounce(fn, ms) {
  let timer;
  return function (...args) {
    clearTimeout(timer);
    timer = setTimeout(() => fn.apply(this, args), ms);
  };
}
