const SUPABASE_URL = 'https://uyznpuzsabmjoxhxqvrg.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV5em5wdXpzYWJtam94aHhxdnJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxMjQyODIsImV4cCI6MjA2MzcwMDI4Mn0.Ym3AtBU9cQJv5mhyz5Y9kWJDXSqQfya-pPGs0Qj58XY';

let supabase; // Declare supabase variable

// Defer initialization until Supabase global is available
// This assumes the CDN script for Supabase has loaded and populated window.supabase
if (window.supabase && typeof window.supabase.createClient === 'function') {
    supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
} else {
    console.error('Supabase client library (window.supabase) not loaded or window.supabase.createClient is not a function. Make sure the Supabase CDN script is loaded before shared.js and has initialized.');
    // Fallback or throw error to prevent further execution if supabase is critical
    // For now, scripts attempting to use 'supabase' will fail if it's not initialized.
}

// Function to display results in a consistent way
function displayResults(containerId, action, data, error) {
    console.log('[shared.js] displayResults called for action:', action, 'containerId:', containerId, 'Data:', data, 'Error:', error); // DEBUG
    const resultsContainer = document.getElementById(containerId);
    if (!resultsContainer) {
        console.error('[shared.js] displayResults: Container with id ' + containerId + ' not found.');
        return;
    }
    const resultDiv = document.createElement('div');
    resultDiv.className = 'result';
    let content = '<h3>' + action + '</h3>';
    if (error) {
        content += '<p class="error">Error: ' + (error.message ? error.message : JSON.stringify(error)) + '</p>';
        console.error('Error during ' + action + ':', error);
    } else {
        content += '<p class="success">Success</p>';
        if (data) {
            content += '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
        }
        console.log('Success during ' + action + ':', data);
    }
    resultDiv.innerHTML = content;
    resultsContainer.appendChild(resultDiv);
}

// Function to clear results
function clearResults(containerId) {
    const resultsContainer = document.getElementById(containerId);
    if (resultsContainer) {
        resultsContainer.innerHTML = '';
    }
}

// Helper to get current user ID
async function getCurrentUserId() {
    if (!supabase) { console.error("Supabase client not initialized in getCurrentUserId"); return null; }
    const { data: { session } } = await supabase.auth.getSession();
    return session?.user?.id || null;
}

// Helper to get current user role
async function getCurrentUserRole() {
    if (!supabase) { console.error("Supabase client not initialized in getCurrentUserRole"); return 'unknown (Supabase not init)'; }
    const userId = await getCurrentUserId();
    if (!userId) return null;

    try {
        const { data, error } = await supabase
            .from('user_profiles')
            .select('role')
            .eq('id', userId)
            .single();

        if (error) {
            console.error('Error fetching user role:', error);
            if (error.code === 'PGRST116') {
                const session = await supabase.auth.getSession();
                if (session && session.data.session) {
                    return 'unknown (profile not accessible)';
                }
                return 'chatter';
            }
            return 'unknown';
        }
        return data ? data.role : 'unknown (no role in profile)';
    } catch (e) {
        console.error('Exception fetching user role:', e);
        return 'unknown (exception)';
    }
}

// Ensure user is logged in before running tests on protected pages
async function ensureLoggedIn() {
    if (!supabase) {
        alert('Supabase client not initialized. Cannot check login state.');
        window.location.href = 'index.html'; // Redirect to login, maybe it fixes itself
        return false;
    }
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) {
        alert('You are not logged in. Please log in on the main page.');
        window.location.href = 'index.html';
        return false;
    }
    const storedSession = localStorage.getItem('supabase.auth.token');
    if (storedSession) {
        const { error } = await supabase.auth.setSession(JSON.parse(storedSession));
        if (error) {
            console.warn("Failed to restore session from localStorage:", error);
        } else {
             console.log("Session restored from localStorage.");
        }
    }
    const { data: { session: refreshedSession } } = await supabase.auth.getSession();
    if (!refreshedSession) {
        alert('Your session has expired or is invalid. Please log in again.');
        window.location.href = 'index.html';
        return false;
    }
    return true;
}

// Common setup for test pages
async function commonPageSetup() {
    if (window.location.pathname !== '/rls_testing_frontend/' && window.location.pathname !== '/rls_testing_frontend/index.html') {
        if (!await ensureLoggedIn()) {
            return;
        }
        if (!supabase) { console.error("Supabase client not initialized in commonPageSetup"); return; }
        const userEmail = supabase.auth.currentUser?.email || 'N/A'; // This might be from an older version of Supabase client, use getSession().data.session.user.email
        const currentUser = (await supabase.auth.getSession())?.data?.session?.user;
        const displayEmail = currentUser?.email || 'N/A';
        const userRole = await getCurrentUserRole();
        const userInfoEl = document.getElementById('currentUserInfo');
        if (userInfoEl) {
            userInfoEl.textContent = 'Testing as: ' + displayEmail + ' (Role guess: ' + userRole + ')';
        }


        const logoutButton = document.getElementById('logoutButton');
        if(logoutButton) {
            logoutButton.addEventListener('click', async () => {
                if (!supabase) { console.error("Supabase client not initialized for logout"); return; }
                await supabase.auth.signOut();
                localStorage.removeItem('supabase.auth.token');
                window.location.href = 'index.html';
            });
        }
    }
}

// Call common setup on page load for relevant pages
// Ensure this runs after supabase might be initialized
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        if (supabase) commonPageSetup(); // Only run if supabase was initialized
        else console.warn("commonPageSetup skipped: Supabase client not initialized at DOMContentLoaded.");
    });
} else {
    if (supabase) commonPageSetup(); // Potentially too early if shared.js runs before DOMContentLoaded and supabase CDN is slow
    else console.warn("commonPageSetup skipped: Supabase client not initialized (immediate execution path).");
}
