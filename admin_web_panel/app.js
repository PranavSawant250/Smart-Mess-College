import { firebaseConfig } from './firebase-config.js';
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js";
import { getFirestore, collection, getDocs, doc, setDoc, updateDoc, onSnapshot, query, where, getDoc, addDoc, serverTimestamp, orderBy } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";
import { getAuth, onAuthStateChanged, signOut, signInWithEmailAndPassword, createUserWithEmailAndPassword } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-auth.js";

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

// State Variables
let sidebarCollapsed = false;
let isDark = false;
let currentPage = '';
let chartInstances = {};
let currentUser = null;
let currentAdminData = null;
let unsubscribeRequests = null;

// DOM Elements
const sb = document.getElementById('sidebar');
const main = document.getElementById('main');
const tb = document.getElementById('topbar');
const overlay = document.getElementById('overlay');
const pageContent = document.getElementById('page-content');

// --- Event Listeners for UI ---
document.getElementById('toggle-btn').addEventListener('click', toggleSidebar);
document.getElementById('theme-btn').addEventListener('click', toggleTheme);
overlay.addEventListener('click', closeMobileSidebar);

document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', (e) => {
        if(item.id === 'logout-btn') {
            handleLogout();
            return;
        }
        const page = item.getAttribute('data-page');
        if(page) setPage(page, item);
    });
});

// --- Auth State ---
onAuthStateChanged(auth, async (user) => {
    if (user) {
        currentUser = user;
        let userDoc = await getDoc(doc(db, 'users', user.uid));
        
        // Handle race condition during signup
        if (!userDoc.exists()) {
            await new Promise(r => setTimeout(r, 1500)); // wait 1.5s for signup to write the doc
            userDoc = await getDoc(doc(db, 'users', user.uid));
        }

        if (userDoc.exists() && userDoc.data().role === 'admin') {
            currentAdminData = { id: user.uid, ...userDoc.data() };
            if(!currentAdminData.messId) currentAdminData.messId = user.uid; 
            
            // Show shell
            sb.style.display = 'flex';
            tb.style.display = 'flex';
            main.style.marginLeft = 'var(--sidebar-w)';
            
            setupRealtimeListeners();
            setPage('dashboard', document.querySelector('.nav-item[data-page="dashboard"]'));
        } else {
            // Not an admin
            sb.style.display = 'none';
            tb.style.display = 'none';
            main.style.marginLeft = '0';
            pageContent.innerHTML = `<div style="padding:40px;text-align:center;color:var(--red);">Access Denied. You must be an admin. <button class="action-btn" id="temp-logout" style="margin-top:10px">Logout</button></div>`;
            document.getElementById('temp-logout')?.addEventListener('click', handleLogout);
        }
    } else {
        currentUser = null;
        currentAdminData = null;
        if(unsubscribeRequests) unsubscribeRequests();
        
        // Hide shell
        sb.style.display = 'none';
        tb.style.display = 'none';
        main.style.marginLeft = '0';
        showAuthUI(true);
    }
});

function showAuthUI(isLogin = true) {
    if (isLogin) {
        pageContent.innerHTML = `
            <div style="max-width:400px; margin: 80px auto; padding:30px; background:var(--surface); border:1px solid var(--border); border-radius:12px; box-shadow: 0 4px 20px rgba(0,0,0,0.05);">
                <h2 style="margin-bottom:20px;text-align:center">Admin Login</h2>
                <form id="login-form">
                    <div class="form-group">
                        <label class="form-label">Email</label>
                        <input type="email" id="login-email" class="form-input" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Password</label>
                        <input type="password" id="login-password" class="form-input" required>
                    </div>
                    <button type="submit" class="action-btn primary" style="width:100%; padding:10px">Secure Login</button>
                    <div id="login-error" style="color:var(--red); margin-top:10px; font-size:13px; text-align:center"></div>
                </form>
                <div style="text-align:center; margin-top:20px; font-size:14px; color:var(--text2);">
                    Don't have an admin account? <a href="#" id="go-to-signup" style="color:var(--primary); text-decoration:none; font-weight:500;">Register here</a>
                </div>
            </div>
        `;
        document.getElementById('login-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('login-email').value;
            const password = document.getElementById('login-password').value;
            try {
                await signInWithEmailAndPassword(auth, email, password);
            } catch(err) {
                document.getElementById('login-error').textContent = err.message;
            }
        });
        document.getElementById('go-to-signup').addEventListener('click', (e) => {
            e.preventDefault();
            showAuthUI(false);
        });
    } else {
        pageContent.innerHTML = `
            <div style="max-width:500px; margin: 40px auto; padding:30px; background:var(--surface); border:1px solid var(--border); border-radius:12px; box-shadow: 0 4px 20px rgba(0,0,0,0.05);">
                <h2 style="margin-bottom:20px;text-align:center">Register as Admin</h2>
                <form id="signup-form" class="grid2">
                    <div class="form-group" style="grid-column: span 2">
                        <label class="form-label">Admin Name</label>
                        <input type="text" id="reg-name" class="form-input" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Phone</label>
                        <input type="tel" id="reg-phone" class="form-input" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Mess Name</label>
                        <input type="text" id="reg-messname" class="form-input" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Mess ID (e.g. AB1234)</label>
                        <input type="text" id="reg-messid" class="form-input" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Email</label>
                        <input type="email" id="reg-email" class="form-input" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Password</label>
                        <input type="password" id="reg-password" class="form-input" required>
                    </div>
                    <div style="grid-column: span 2">
                        <button type="submit" class="action-btn primary" style="width:100%; padding:10px">Create Admin Account</button>
                        <div id="signup-error" style="color:var(--red); margin-top:10px; font-size:13px; text-align:center"></div>
                    </div>
                </form>
                <div style="text-align:center; margin-top:20px; font-size:14px; color:var(--text2);">
                    Already have an account? <a href="#" id="go-to-login" style="color:var(--primary); text-decoration:none; font-weight:500;">Login here</a>
                </div>
            </div>
        `;
        document.getElementById('go-to-login').addEventListener('click', (e) => {
            e.preventDefault();
            showAuthUI(true);
        });
        document.getElementById('signup-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const btn = e.target.querySelector('button[type="submit"]');
            btn.textContent = 'Registering...';
            btn.disabled = true;
            try {
                const userCred = await createUserWithEmailAndPassword(auth, 
                    document.getElementById('reg-email').value, 
                    document.getElementById('reg-password').value
                );
                const uid = userCred.user.uid;
                
                // Create Mess Doc
                const messIdInput = document.getElementById('reg-messid').value;
                const messRef = doc(db, 'messes', messIdInput);
                await setDoc(messRef, {
                    messName: document.getElementById('reg-messname').value,
                    adminId: uid,
                    monthlyFee: 0,
                    address: '',
                    description: '',
                    upiId: '',
                    qrCodeImage: '',
                    createdAt: serverTimestamp()
                });
                
                // Create User Doc
                await setDoc(doc(db, 'users', uid), {
                    name: document.getElementById('reg-name').value,
                    email: document.getElementById('reg-email').value,
                    phone: document.getElementById('reg-phone').value,
                    role: 'admin',
                    messId: messIdInput,
                    createdAt: serverTimestamp()
                });
                
                // onAuthStateChanged will handle the rest
            } catch(err) {
                document.getElementById('signup-error').textContent = err.message;
                btn.textContent = 'Create Admin Account';
                btn.disabled = false;
            }
        });
    }
}

function handleLogout() {
    signOut(auth);
}

function setupRealtimeListeners() {
    const messId = currentAdminData.messId;
    unsubscribeRequests = onSnapshot(query(collection(db, 'join_requests'), where('messId', '==', messId), where('status', '==', 'pending')), (snap) => {
        document.getElementById('badge-requests').textContent = snap.size;
    });
}

// --- UI Functions ---
function toggleSidebar() {
  if (window.innerWidth <= 640) {
    sb.classList.toggle('mobile-open');
    overlay.style.display = sb.classList.contains('mobile-open') ? 'block' : 'none';
  } else {
    sidebarCollapsed = !sidebarCollapsed;
    sb.classList.toggle('collapsed', sidebarCollapsed);
    main.classList.toggle('collapsed', sidebarCollapsed);
    tb.classList.toggle('collapsed', sidebarCollapsed);
  }
}

function closeMobileSidebar() {
  sb.classList.remove('mobile-open');
  overlay.style.display = 'none';
}

function toggleTheme() {
  isDark = !isDark;
  document.documentElement.setAttribute('data-theme', isDark ? 'dark' : '');
  document.getElementById('theme-icon-sun').style.display = isDark ? 'none' : '';
  document.getElementById('theme-icon-moon').style.display = isDark ? '' : 'none';
  if(currentPage === 'dashboard') setTimeout(renderCharts, 50);
}

function setPage(page, targetElement) {
    currentPage = page;
    document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
    if(targetElement) targetElement.classList.add('active');
    
    document.getElementById('topbar-title').textContent = page.charAt(0).toUpperCase() + page.slice(1).replace(/([A-Z])/g, ' $1');
    renderPage(page);
    closeMobileSidebar();
}

function destroyCharts() {
  Object.values(chartInstances).forEach(c => c && c.destroy());
  chartInstances = {};
}

function badgeHtml(status){
  const map = {approved:'success',pending:'warning',rejected:'danger',paid:'success',overdue:'danger',active:'info'};
  return `<span class="badge ${map[status]||'info'}">${status.charAt(0).toUpperCase()+status.slice(1)}</span>`;
}

// --- Page Rendering ---
async function renderPage(page) {
  destroyCharts();
  pageContent.innerHTML = '<div style="text-align:center; padding: 50px;">Loading Data...</div>';
  
  try {
      if (page === 'dashboard') {
        pageContent.innerHTML = await buildDashboardHTML();
        setTimeout(renderCharts, 80);
      } else if (page === 'settings') {
        pageContent.innerHTML = await buildSettingsHTML();
        setupSettingsEvents();
      } else if (page === 'requests') {
        pageContent.innerHTML = await buildRequestsHTML();
        setupRequestsEvents();
      } else if (page === 'students') {
        pageContent.innerHTML = await buildStudentsHTML();
        setupStudentsEvents();
      } else if (page === 'polls') {
        pageContent.innerHTML = await buildPollsHTML();
        setupPollsEvents();
      } else if (page === 'orders') {
        pageContent.innerHTML = await buildOrdersHTML();
      } else if (page === 'feedback') {
        pageContent.innerHTML = await buildFeedbackHTML();
      } else if (page === 'transactions') {
        pageContent.innerHTML = await buildTransactionsHTML();
        setupTransactionsEvents();
      } else {
        pageContent.innerHTML = `<div style="display:flex;flex-direction:column;align-items:center;justify-content:center;height:300px;color:var(--text2)">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="opacity:.3;margin-bottom:12px"><rect x="3" y="3" width="18" height="18" rx="3"/><path d="M9 9h6M9 12h6M9 15h4"/></svg>
          <div style="font-size:16px;font-weight:500;margin-bottom:6px">${page.charAt(0).toUpperCase()+page.slice(1)} Page</div>
          <div style="font-size:13px">Module coming soon...</div>
        </div>`;
      }
  } catch (error) {
      console.error("Error loading page data:", error);
      pageContent.innerHTML = `<div style="color:var(--red); padding: 20px;">Error loading data. ${error.message}</div>`;
  }
}

// --- Dashboard ---
async function buildDashboardHTML() {
  const messId = currentAdminData.messId;
  
  // Get counts
  const usersSnap = await getDocs(query(collection(db, 'users'), where('messId', '==', messId), where('role', '==', 'student')));
  const totalStudents = usersSnap.size;

  const reqSnap = await getDocs(query(collection(db, 'join_requests'), where('messId', '==', messId), where('status', '==', 'pending')));
  const pendingRequests = reqSnap.size;

  // Get recent requests
  let reqHtml = '';
  if(pendingRequests > 0) {
      const topRequests = reqSnap.docs.slice(0, 5);
      for(let docSnap of topRequests) {
          const reqData = docSnap.data();
          const sUserDoc = await getDoc(doc(db, 'users', reqData.studentId));
          const sUser = sUserDoc.exists() ? sUserDoc.data() : {name:'Unknown', prn:'N/A'};
          
          reqHtml += `<tr>
            <td><div style="display:flex;align-items:center;gap:8px">
              <div class="av-sm" style="background:var(--primary-light);color:var(--primary)">${sUser.name.split(' ').map(x=>x[0]).join('').substring(0,2)}</div>
              <span style="font-weight:500">${sUser.name}</span>
            </div></td>
            <td style="color:var(--text2);font-family:monospace;font-size:12px">${sUser.prn}</td>
            <td>${badgeHtml(reqData.status)}</td>
          </tr>`;
      }
  } else {
      reqHtml = `<tr><td colspan="3" style="text-align:center; color:var(--text2)">No pending requests</td></tr>`;
  }

  return `
  <div class="welcome-band">
    <div style="position:relative;z-index:1">
      <div class="welcome-title">Welcome back, Admin! 👋</div>
      <div class="welcome-sub">${new Date().toLocaleDateString('en-IN',{weekday:'long',year:'numeric',month:'long',day:'numeric'})}</div>
    </div>
  </div>

  <div class="grid6" style="margin-bottom:20px">
    <div class="stat-card">
      <div><div class="stat-label">Total Students</div><div class="stat-val">${totalStudents}</div></div>
    </div>
    <div class="stat-card">
      <div><div class="stat-label">Pending Requests</div><div class="stat-val">${pendingRequests}</div></div>
    </div>
  </div>

  <div class="grid3" style="margin-bottom:20px">
    <div class="card"><div class="chart-wrap"><canvas id="chartGrowth"></canvas></div></div>
    <div class="card"><div class="chart-wrap"><canvas id="chartRevenue"></canvas></div></div>
  </div>

  <div class="card" style="overflow:hidden;padding:0">
    <div style="padding:18px 20px 12px" class="section-header">
      <div class="section-title">Recent Join Requests</div>
      <div class="view-all" onclick="document.querySelector('.nav-item[data-page=\\'requests\\']').click()">View All</div>
    </div>
    <div style="overflow-x:auto">
      <table><thead><tr><th>Name</th><th>PRN</th><th>Status</th></tr></thead>
      <tbody>${reqHtml}</tbody></table>
    </div>
  </div>
  `;
}

// --- Settings ---
async function buildSettingsHTML() {
    const messId = currentAdminData.messId;
    const messDoc = await getDoc(doc(db, 'messes', messId));
    const data = messDoc.exists() ? messDoc.data() : { messName: '', monthlyFee: '', adminId: currentAdminData.id, upiId: '', qrCodeImage: '', description: '' };
    
    return `
    <div class="card">
        <div class="section-header">
            <div class="section-title">Mess Settings & Config</div>
        </div>
        <form id="settings-form">
            <div class="grid2">
                <div class="form-group">
                    <label class="form-label">Mess Name</label>
                    <input type="text" id="set-name" class="form-input" value="${data.messName || ''}" required>
                </div>
                <div class="form-group">
                    <label class="form-label">Monthly Fee (₹)</label>
                    <input type="number" id="set-fees" class="form-input" value="${data.monthlyFee || ''}" required>
                </div>
                <div class="form-group">
                    <label class="form-label">UPI ID</label>
                    <input type="text" id="set-upi" class="form-input" value="${data.upiId || ''}" required>
                </div>
                <div class="form-group">
                    <label class="form-label">QR Code Image (Upload)</label>
                    <input type="file" id="set-qr" accept="image/*" class="form-input">
                    ${data.qrCodeImage ? `<img src="${data.qrCodeImage}" style="height:60px; margin-top:10px; border-radius:8px; border:1px solid var(--border)">` : ''}
                    <input type="hidden" id="set-qr-hidden" value="${data.qrCodeImage || ''}">
                </div>
            </div>
            <div class="form-group">
                <label class="form-label">Mess Description</label>
                <textarea id="set-desc" class="form-textarea">${data.description || ''}</textarea>
            </div>
            <button class="action-btn primary" type="submit" id="save-settings-btn">Save Settings to Firebase</button>
            <div id="settings-msg" style="margin-top:10px; font-size:13px; color:var(--green);"></div>
        </form>
    </div>
    `;
}

function setupSettingsEvents() {
    const qrInput = document.getElementById('set-qr');
    const qrHidden = document.getElementById('set-qr-hidden');

    qrInput?.addEventListener('change', (e) => {
        const file = e.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (event) => {
                qrHidden.value = event.target.result;
            };
            reader.readAsDataURL(file);
        }
    });

    document.getElementById('settings-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = document.getElementById('save-settings-btn');
        btn.textContent = 'Saving...';
        
        const data = {
            messName: document.getElementById('set-name').value,
            monthlyFee: parseFloat(document.getElementById('set-fees').value),
            upiId: document.getElementById('set-upi').value,
            qrCodeImage: qrHidden.value,
            description: document.getElementById('set-desc').value,
        };
        try {
            await updateDoc(doc(db, 'messes', currentAdminData.messId), data);
            document.getElementById('settings-msg').textContent = 'Settings updated successfully!';
            btn.textContent = 'Save Settings to Firebase';
        } catch(err) {
            document.getElementById('settings-msg').style.color = 'var(--red)';
            document.getElementById('settings-msg').textContent = err.message;
            btn.textContent = 'Save Settings to Firebase';
        }
    });
}

// --- Requests ---
async function buildRequestsHTML() {
    const messId = currentAdminData.messId;
    const reqSnap = await getDocs(query(collection(db, 'join_requests'), where('messId', '==', messId), where('status', '==', 'pending')));
    
    let html = '';
    for(let docSnap of reqSnap.docs) {
        const req = docSnap.data();
        const reqId = docSnap.id;
        const sUserDoc = await getDoc(doc(db, 'users', req.studentId));
        const sUser = sUserDoc.exists() ? sUserDoc.data() : {name:'Unknown', prn:'N/A'};
        
        html += `<tr>
            <td>
                <span class="view-profile-btn" style="font-weight:600; cursor:pointer; color:var(--primary); text-decoration:underline"
                      data-name="${sUser.name || ''}"
                      data-prn="${sUser.prn || ''}"
                      data-branch="${sUser.branch || ''}"
                      data-year="${sUser.passoutYear || ''}"
                      data-hostel="${sUser.hostelName || ''}"
                      data-email="${sUser.email || ''}"
                      data-phone="${sUser.phone || ''}"
                      title="Click to view full profile">
                    ${sUser.name}
                </span>
            </td>
            <td>${sUser.prn}</td>
            <td>${badgeHtml(req.status)}</td>
            <td>
                <div style="font-size:13px; line-height:1.4;">
                    <div><b>Mode:</b> ${req.paymentMode || 'N/A'}</div>
                    ${req.transactionId ? `<div><b style="color:var(--primary)">Txn ID:</b> <span style="font-family:monospace">${req.transactionId}</span></div>` : ''}
                </div>
            </td>
            <td>
                <button class="action-btn primary req-approve" data-id="${reqId}" data-studentid="${req.studentId}">Approve</button>
                <button class="action-btn req-reject" data-id="${reqId}" style="color:var(--red)">Reject</button>
            </td>
        </tr>`;
    }
    
    if(reqSnap.empty) {
        html = '<tr><td colspan="5" style="text-align:center;color:var(--text2)">No pending requests.</td></tr>';
    }

    return `
    <div class="card">
        <div class="section-header">
            <div class="section-title">Manage Join Requests</div>
        </div>
        <table>
            <thead><tr><th>Name</th><th>PRN</th><th>Status</th><th>Payment Info</th><th>Actions</th></tr></thead>
            <tbody>${html}</tbody>
        </table>
    </div>
    `;
}

function setupRequestsEvents() {
    document.querySelectorAll('.view-profile-btn').forEach(btn => {
        btn.addEventListener('click', (e) => window.showStudentProfile(e.target.dataset));
    });

    document.querySelectorAll('.req-approve').forEach(btn => {
        btn.addEventListener('click', async (e) => {
            const reqId = e.target.getAttribute('data-id');
            const studentId = e.target.getAttribute('data-studentid');
            try {
                // Get current count of students in this mess to generate a serial number
                const messUsersSnap = await getDocs(query(collection(db, 'users'), where('messId', '==', currentAdminData.messId)));
                // It might include admins if admin has same messId, so let's filter for students
                let studentCount = 0;
                messUsersSnap.forEach(docSnap => {
                    if (docSnap.data().role === 'student') studentCount++;
                });
                const nextId = (studentCount + 1).toString();

                // Update request
                await updateDoc(doc(db, 'join_requests', reqId), { status: 'approved' });
                // Update user
                await updateDoc(doc(db, 'users', studentId), { 
                    messId: currentAdminData.messId,
                    messStudentId: nextId
                });
                alert(`Student approved! Assigned Mess Student ID: ${nextId}`);
                renderPage('requests');
            } catch(err) {
                alert("Error: " + err.message);
            }
        });
    });
    
    document.querySelectorAll('.req-reject').forEach(btn => {
        btn.addEventListener('click', async (e) => {
            const reqId = e.target.getAttribute('data-id');
            if(confirm("Are you sure you want to reject this request?")) {
                try {
                    await updateDoc(doc(db, 'join_requests', reqId), { status: 'rejected' });
                    alert("Request rejected.");
                    renderPage('requests');
                } catch(err) {
                    alert("Error: " + err.message);
                }
            }
        });
    });
}

// --- Students ---
async function buildStudentsHTML() {
    const messId = currentAdminData.messId;
    const usersSnap = await getDocs(query(collection(db, 'users'), where('messId', '==', messId)));
    
    let html = '';
    usersSnap.forEach(docSnap => {
        const user = docSnap.data();
        if(user.role === 'student') {
            html += `<tr>
                <td>
                    <span class="view-profile-btn" style="font-weight:600; cursor:pointer; color:var(--primary); text-decoration:underline"
                          data-name="${user.name || ''}"
                          data-prn="${user.prn || ''}"
                          data-branch="${user.branch || ''}"
                          data-year="${user.passoutYear || ''}"
                          data-hostel="${user.hostelName || ''}"
                          data-email="${user.email || ''}"
                          data-phone="${user.phone || ''}"
                          title="Click to view full profile">
                        ${user.name || 'N/A'}
                    </span>
                </td>
                <td>${user.prn || 'N/A'}</td>
                <td>${user.email || 'N/A'}</td>
                <td><button class="action-btn" style="color:var(--red)" onclick="alert('Removal functionality coming soon')">Remove</button></td>
            </tr>`;
        }
    });
    
    if(!html) {
        html = '<tr><td colspan="4" style="text-align:center;color:var(--text2)">No active students.</td></tr>';
    }
    
    return `
    <div class="card">
        <div class="section-header" style="display:flex; justify-content:space-between; align-items:center;">
            <div class="section-title">Enrolled Students</div>
            <input type="text" id="student-search" placeholder="Search students..." class="form-input" style="width: 250px; padding: 6px 12px; font-size:14px;">
        </div>
        <table>
            <thead><tr><th>Name</th><th>PRN</th><th>Email</th><th>Actions</th></tr></thead>
            <tbody id="students-tbody">${html}</tbody>
        </table>
    </div>
    `;
}

window.showStudentProfile = function(ds) {
    const modal = document.createElement('div');
    modal.style.position = 'fixed';
    modal.style.top = '0'; modal.style.left = '0'; modal.style.width = '100%'; modal.style.height = '100%';
    modal.style.backgroundColor = 'rgba(0,0,0,0.5)';
    modal.style.display = 'flex';
    modal.style.alignItems = 'center';
    modal.style.justifyContent = 'center';
    modal.style.zIndex = '9999';

    modal.innerHTML = `
        <div style="background:var(--background); padding:30px; border-radius:16px; width:400px; max-width:90%; position:relative; box-shadow:0 10px 25px rgba(0,0,0,0.2)">
            <button onclick="this.parentElement.parentElement.remove()" style="position:absolute; top:15px; right:15px; background:none; border:none; font-size:20px; cursor:pointer; color:var(--text2)">&times;</button>
            <h3 style="margin-top:0; color:var(--primary); font-size:20px; margin-bottom:20px; border-bottom:1px solid var(--border); padding-bottom:10px;">Student Profile</h3>
            
            <div style="display:grid; grid-template-columns: 100px 1fr; gap:12px; font-size:14px; line-height:1.6">
                <b style="color:var(--text2)">Name:</b> <span style="color:var(--text)">${ds.name || 'N/A'}</span>
                <b style="color:var(--text2)">PRN:</b> <span style="color:var(--text)">${ds.prn || 'N/A'}</span>
                <b style="color:var(--text2)">Branch:</b> <span style="color:var(--text)">${ds.branch || 'N/A'}</span>
                <b style="color:var(--text2)">Passout:</b> <span style="color:var(--text)">${ds.year || 'N/A'}</span>
                <b style="color:var(--text2)">Hostel:</b> <span style="color:var(--text)">${ds.hostel || 'N/A'}</span>
                <b style="color:var(--text2)">Email:</b> <span style="color:var(--text)">${ds.email || 'N/A'}</span>
                <b style="color:var(--text2)">Phone:</b> <span style="color:var(--text)">${ds.phone || 'N/A'}</span>
            </div>
            
            <button onclick="this.parentElement.parentElement.remove()" class="action-btn primary" style="width:100%; margin-top:24px; padding:10px">Close</button>
        </div>
    `;
    document.body.appendChild(modal);
};

function setupStudentsEvents() {
    const searchInput = document.getElementById('student-search');
    if(searchInput) {
        searchInput.addEventListener('input', (e) => {
            const query = e.target.value.toLowerCase();
            document.querySelectorAll('#students-tbody tr').forEach(row => {
                const text = row.innerText.toLowerCase();
                row.style.display = text.includes(query) ? '' : 'none';
            });
        });
    }

    document.querySelectorAll('.view-profile-btn').forEach(btn => {
        btn.addEventListener('click', (e) => window.showStudentProfile(e.target.dataset));
    });
}

// Chart Render logic
function getChartColors(){
  const d = isDark;
  return { gridColor: d ? 'rgba(255,255,255,0.07)' : 'rgba(0,0,0,0.07)', tickColor: d ? '#64748b' : '#9ca3af' };
}

function renderCharts(){
  const {gridColor,tickColor} = getChartColors();
  const baseOpts = {
    responsive:true, maintainAspectRatio:false,
    plugins:{legend:{display:false}},
    scales:{
      x:{grid:{color:gridColor},ticks:{color:tickColor,font:{size:11}}},
      y:{grid:{color:gridColor},ticks:{color:tickColor,font:{size:11}}}
    }
  };

  const g1 = document.getElementById('chartGrowth');
  if(g1){
    chartInstances.growth = new Chart(g1,{
      type:'line',
      data:{
        labels:['Jan','Feb','Mar','Apr','May','Jun'],
        datasets:[{
          label:'Students', data:[120,140,165,190,210,242],
          borderColor:'#4f46e5',backgroundColor:'rgba(79,70,229,0.1)', fill:true,tension:.4
        }]
      }, options: baseOpts
    });
  }
}

// --- Polls ---
async function buildPollsHTML() {
    const messId = currentAdminData.messId;
    const pollsSnap = await getDocs(query(collection(db, 'polls'), where('messId', '==', messId)));
    
    let activeHtml = '';
    let pastHtml = '';

    const sortedDocs = pollsSnap.docs.map(d => ({id: d.id, ...d.data()})).sort((a, b) => {
        const timeA = a.createdAt?.toMillis ? a.createdAt.toMillis() : 0;
        const timeB = b.createdAt?.toMillis ? b.createdAt.toMillis() : 0;
        return timeB - timeA;
    });

    const getWinnerStr = (opts) => {
        if(!opts || !Array.isArray(opts) || opts.length === 0) return 'None (0 votes)';
        const winner = opts.reduce((a, b) => ((a.votes||0) > (b.votes||0)) ? a : b);
        return `${winner.name} (${winner.votes||0} votes)`;
    };

    sortedDocs.forEach(p => {
        if (!p.isActive) return;

        const pid = p.id;
        const timeStr = p.date?.toDate ? p.date.toDate().toLocaleDateString('en-IN') : (p.date || 'Unknown');
        const v = p.totalVeg || 0;
        const nv = p.totalNonVeg || 0;
        const f = p.totalFast || 0;
        const totalVotes = v + nv + f;
        
        const vPct = totalVotes ? (v / totalVotes) * 100 : 0;
        const nvPct = totalVotes ? (nv / totalVotes) * 100 : 0;
        const fPct = totalVotes ? (f / totalVotes) * 100 : 0;
        
        let card = `
        <div style="background:var(--card-bg, #fff); border-radius:12px; padding:20px; box-shadow:0 4px 6px rgba(0,0,0,0.05); margin-bottom:20px; border:1px solid var(--border);">
            <div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:12px; flex-wrap:wrap; gap:12px;">
                <div>
                    <h3 style="margin:0; font-size:18px; color:var(--text);">${p.title || 'Poll'}</h3>
                    <div style="color:var(--text2); font-size:14px; margin-top:4px;">${timeStr} (${p.mealTime}) • Total: ${totalVotes} participants</div>
                </div>
                <div>
                    <button class="action-btn primary poll-finalize" data-id="${pid}">Finalize Poll</button>
                </div>
            </div>
            
            <div style="margin-top:20px; display:flex; flex-direction:column; gap:12px;">
                <div style="display:flex; align-items:center; gap:12px;">
                    <div style="width:90px; font-weight:600; color:#059669; display:flex; align-items:center; gap:6px;">🌿 Veg</div>
                    <div style="flex:1; background:#ecfdf5; height:12px; border-radius:6px; overflow:hidden;">
                        <div style="width:${vPct}%; background:#059669; height:100%;"></div>
                    </div>
                    <div style="width:30px; font-weight:600; color:#059669; text-align:right;">${v}</div>
                </div>
                <div style="display:flex; align-items:center; gap:12px;">
                    <div style="width:90px; font-weight:600; color:#dc2626; display:flex; align-items:center; gap:6px;">🍗 Non-Veg</div>
                    <div style="flex:1; background:#fef2f2; height:12px; border-radius:6px; overflow:hidden;">
                        <div style="width:${nvPct}%; background:#dc2626; height:100%;"></div>
                    </div>
                    <div style="width:30px; font-weight:600; color:#dc2626; text-align:right;">${nv}</div>
                </div>
                <div style="display:flex; align-items:center; gap:12px;">
                    <div style="width:90px; font-weight:600; color:#d97706; display:flex; align-items:center; gap:6px;">🧘 Fast</div>
                    <div style="flex:1; background:#fffbeb; height:12px; border-radius:6px; overflow:hidden;">
                        <div style="width:${fPct}%; background:#d97706; height:100%;"></div>
                    </div>
                    <div style="width:30px; font-weight:600; color:#d97706; text-align:right;">${f}</div>
                </div>
            </div>
            
            <div style="margin-top:20px; padding-top:16px; border-top:1px dashed var(--border); display:flex; flex-direction:column; gap:8px; font-size:14px;">
                <div><b style="color:#059669">🏆 Top Veg:</b> ${getWinnerStr(p.vegOptions)}</div>
                <div><b style="color:#dc2626">🏆 Top Non-Veg:</b> ${getWinnerStr(p.nonVegOptions)}</div>
                <div><b style="color:#d97706">🏆 Top Fast:</b> ${getWinnerStr(p.fastOptions)}</div>
            </div>
        </div>`;

        activeHtml += card;
    });

    if(!activeHtml) activeHtml = '<div style="text-align:center;color:var(--text2);padding:20px;">No active polls</div>';

    return `
    <div class="card" style="margin-bottom:20px;">
        <div class="section-header">
            <div class="section-title">Create New Poll</div>
        </div>
        <form id="create-poll-form" class="grid2">
            
            <div class="form-group" style="grid-column: span 2">
                <label class="form-label">Poll Title</label>
                <input type="text" id="poll-title" class="form-input" value="Today's Lunch Poll" required>
            </div>

            <div class="form-group">
                <label class="form-label">Meal Time</label>
                <select id="poll-mealtime" class="form-input" onchange="document.getElementById('poll-title').value = 'Today\\'s ' + this.value + ' Poll'">
                    <option value="Breakfast">Breakfast</option>
                    <option value="Lunch" selected>Lunch</option>
                    <option value="Dinner">Dinner</option>
                </select>
            </div>
            <div></div> <!-- empty grid cell -->

            <div class="form-group">
                <label class="form-label">Poll Start Time</label>
                <input type="datetime-local" id="poll-start" class="form-input" required>
            </div>
            
            <div class="form-group">
                <label class="form-label">Poll End Time</label>
                <input type="datetime-local" id="poll-end" class="form-input" required>
            </div>

            <div class="form-group" style="grid-column: span 2; border:1px solid #d1fae5; padding:15px; border-radius:8px; background:#ecfdf5;">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                    <label class="form-label" style="margin:0; color:#059669; font-weight:bold;">🌿 Veg Options</label>
                    <button type="button" class="action-btn" onclick="addPollOption('veg')" style="padding:4px 8px; font-size:12px; background:white; color:#059669; border:1px solid #059669;">+ Add Option</button>
                </div>
                <div id="veg-options-container">
                    <input type="text" class="form-input veg-opt" placeholder="e.g. Dal Tadka + Rice" style="margin-bottom:8px" required>
                </div>
            </div>

            <div class="form-group" style="grid-column: span 2; border:1px solid #fee2e2; padding:15px; border-radius:8px; background:#fef2f2;">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                    <label class="form-label" style="margin:0; color:#dc2626; font-weight:bold;">🍗 Non-Veg Options</label>
                    <button type="button" class="action-btn" onclick="addPollOption('nonveg')" style="padding:4px 8px; font-size:12px; background:white; color:#dc2626; border:1px solid #dc2626;">+ Add Option</button>
                </div>
                <div id="nonveg-options-container">
                    <input type="text" class="form-input nonveg-opt" placeholder="e.g. Chicken Curry + Rice" style="margin-bottom:8px" required>
                </div>
            </div>

            <div class="form-group" style="grid-column: span 2; border:1px solid #fef3c7; padding:15px; border-radius:8px; background:#fffbeb;">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                    <label class="form-label" style="margin:0; color:#d97706; font-weight:bold;">🧘 Fasting Options</label>
                    <button type="button" class="action-btn" onclick="addPollOption('fast')" style="padding:4px 8px; font-size:12px; background:white; color:#d97706; border:1px solid #d97706;">+ Add Option</button>
                </div>
                <div id="fast-options-container">
                    <input type="text" class="form-input fast-opt" placeholder="e.g. Sabudana Khichdi" style="margin-bottom:8px" required>
                </div>
            </div>

            <div style="grid-column: span 2">
                <button type="submit" id="create-poll-btn" class="action-btn primary" style="width:100%;padding:12px; font-size:16px;">PUBLISH POLL</button>
                <div id="poll-msg" style="margin-top:10px; font-size:13px; text-align:center;"></div>
            </div>
        </form>
    </div>

    <div class="card" style="margin-bottom:20px; background:transparent; box-shadow:none; padding:0; border:none;">
        <div class="section-header">
            <div class="section-title" style="padding-left:10px;">Active Polls & Analysis</div>
        </div>
        ${activeHtml}
    </div>
    `;
}

function setupPollsEvents() {
    // Set default times (Now to Now+4hrs)
    const now = new Date();
    const fourHrsLater = new Date(now.getTime() + 4 * 60 * 60 * 1000);
    const toLocalISO = (d) => new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
    document.getElementById('poll-start').value = toLocalISO(now);
    document.getElementById('poll-end').value = toLocalISO(fourHrsLater);

    // Dynamic Option Add logic
    window.addPollOption = function(type) {
        const container = document.getElementById(`${type}-options-container`);
        const input = document.createElement('input');
        input.type = 'text';
        input.className = `form-input ${type}-opt`;
        input.style.marginBottom = '8px';
        input.placeholder = `Add another ${type} option...`;
        container.appendChild(input);
    };

    document.getElementById('create-poll-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const btn = document.getElementById('create-poll-btn');
        btn.textContent = 'Publishing...';
        
        // Extract dynamically added options
        const getOptions = (type, prefix) => {
            const inputs = document.querySelectorAll(`.${type}-opt`);
            let id = 1;
            let options = [];
            inputs.forEach(input => {
                if(input.value.trim() !== '') {
                    options.push({
                        id: `${prefix}${id++}`,
                        name: input.value.trim(),
                        description: '',
                        votes: 0
                    });
                }
            });
            return options;
        };

        const payload = {
            messId: currentAdminData.messId,
            title: document.getElementById('poll-title').value,
            mealTime: document.getElementById('poll-mealtime').value,
            pollStartTime: new Date(document.getElementById('poll-start').value).toISOString(),
            pollEndTime: new Date(document.getElementById('poll-end').value).toISOString(),
            vegOptions: getOptions('veg', 'nv_'),
            nonVegOptions: getOptions('nonveg', 'nnv_'),
            fastOptions: getOptions('fast', 'nf_'),
            isActive: true,
            isFinalized: false,
            totalVeg: 0,
            totalNonVeg: 0,
            totalFast: 0,
            totalNotComing: 0,
            date: serverTimestamp(),
            createdAt: serverTimestamp()
        };

        try {
            await addDoc(collection(db, 'polls'), payload);
            const msg = document.getElementById('poll-msg');
            msg.style.color = 'var(--green)';
            msg.textContent = "Poll successfully published!";
            btn.textContent = 'PUBLISH POLL';
            setTimeout(() => {
                msg.textContent='';
                document.getElementById('create-poll-form').reset();
                renderPage('polls');
            }, 1500);
        } catch(err) {
            const msg = document.getElementById('poll-msg');
            msg.style.color = 'var(--red)';
            msg.textContent = "Error: " + err.message;
            btn.textContent = 'PUBLISH POLL';
        }
    });

    document.querySelectorAll('.poll-finalize').forEach(btn => {
        btn.addEventListener('click', async (e) => {
            const pollId = e.target.getAttribute('data-id');
            const originalText = e.target.textContent;
            e.target.textContent = "Processing...";
            e.target.disabled = true;

            try {
                const pollDoc = await getDoc(doc(db, 'polls', pollId));
                if (!pollDoc.exists()) throw new Error("Poll not found.");
                
                const pollData = pollDoc.data();
                
                const getWinner = (opts) => {
                    if(!opts || !Array.isArray(opts) || opts.length === 0) return 'N/A';
                    return opts.reduce((a, b) => ((a.votes||0) > (b.votes||0)) ? a : b).name || 'N/A';
                };

                const finalVeg = getWinner(pollData.vegOptions);
                const finalNonVeg = getWinner(pollData.nonVegOptions);
                const finalFast = getWinner(pollData.fastOptions);

                await addDoc(collection(db, 'kitchen_orders'), {
                    messId: currentAdminData.messId,
                    pollId: pollId,
                    date: pollData.date || serverTimestamp(),
                    mealTime: pollData.mealTime || 'Unknown',
                    vegCount: pollData.totalVeg || 0,
                    nonVegCount: pollData.totalNonVeg || 0,
                    fastCount: pollData.totalFast || 0,
                    finalVegMenu: finalVeg,
                    finalNonVegMenu: finalNonVeg,
                    finalFastMenu: finalFast,
                    sentAt: serverTimestamp(),
                    createdAt: serverTimestamp()
                });

                await updateDoc(doc(db, 'polls', pollId), {
                    isActive: false,
                    isFinalized: true,
                    finalizedVeg: finalVeg,
                    finalizedNonVeg: finalNonVeg,
                    finalizedFast: finalFast
                });

                alert('Poll Finalized and Kitchen Order Sent!');
                renderPage('polls');
            } catch(err) {
                alert('Error finalizing: ' + err.message);
                console.error(err);
                e.target.textContent = originalText;
                e.target.disabled = false;
            }
        });
    });
}

// --- Orders ---
async function buildOrdersHTML() {
    const messId = currentAdminData.messId;
    const ordersSnap = await getDocs(query(collection(db, 'kitchen_orders'), where('messId', '==', messId)));
    
    let html = '';
    const sortedDocs = ordersSnap.docs.map(d => ({id: d.id, ...d.data()})).sort((a, b) => {
        const timeA = a.createdAt?.toMillis ? a.createdAt.toMillis() : 0;
        const timeB = b.createdAt?.toMillis ? b.createdAt.toMillis() : 0;
        return timeB - timeA;
    });

    sortedDocs.forEach(p => {
        const timeStr = p.date?.toDate ? p.date.toDate().toLocaleDateString('en-IN') : (p.date || 'Unknown');
        const v = p.vegCount || 0;
        const nv = p.nonVegCount || 0;
        const f = p.fastCount || 0;
        const totalVotes = v + nv + f;
        
        const vPct = totalVotes ? (v / totalVotes) * 100 : 0;
        const nvPct = totalVotes ? (nv / totalVotes) * 100 : 0;
        const fPct = totalVotes ? (f / totalVotes) * 100 : 0;
        
        let card = `
        <div style="background:var(--card-bg, #fff); border-radius:12px; padding:20px; box-shadow:0 4px 6px rgba(0,0,0,0.05); margin-bottom:20px; border:1px solid var(--border);">
            <div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:12px; flex-wrap:wrap; gap:12px;">
                <div>
                    <h3 style="margin:0; font-size:18px; color:var(--text);">${p.title || 'Kitchen Order'}</h3>
                    <div style="color:var(--text2); font-size:14px; margin-top:4px;">${timeStr} (${p.mealTime}) • Total: ${totalVotes} participants</div>
                </div>
                <div>
                    <span class="badge success" style="padding:6px 12px; font-size:14px; border-radius:20px;">Finalized</span>
                </div>
            </div>
            
            <div style="margin-top:20px; display:flex; flex-direction:column; gap:12px;">
                <div style="display:flex; align-items:center; gap:12px;">
                    <div style="width:90px; font-weight:600; color:#059669; display:flex; align-items:center; gap:6px;">🌿 Veg</div>
                    <div style="flex:1; background:#ecfdf5; height:12px; border-radius:6px; overflow:hidden;">
                        <div style="width:${vPct}%; background:#059669; height:100%;"></div>
                    </div>
                    <div style="width:30px; font-weight:600; color:#059669; text-align:right;">${v}</div>
                </div>
                <div style="display:flex; align-items:center; gap:12px;">
                    <div style="width:90px; font-weight:600; color:#dc2626; display:flex; align-items:center; gap:6px;">🍗 Non-Veg</div>
                    <div style="flex:1; background:#fef2f2; height:12px; border-radius:6px; overflow:hidden;">
                        <div style="width:${nvPct}%; background:#dc2626; height:100%;"></div>
                    </div>
                    <div style="width:30px; font-weight:600; color:#dc2626; text-align:right;">${nv}</div>
                </div>
                <div style="display:flex; align-items:center; gap:12px;">
                    <div style="width:90px; font-weight:600; color:#d97706; display:flex; align-items:center; gap:6px;">🧘 Fast</div>
                    <div style="flex:1; background:#fffbeb; height:12px; border-radius:6px; overflow:hidden;">
                        <div style="width:${fPct}%; background:#d97706; height:100%;"></div>
                    </div>
                    <div style="width:30px; font-weight:600; color:#d97706; text-align:right;">${f}</div>
                </div>
            </div>
            
            <div style="margin-top:20px; padding-top:16px; border-top:1px dashed var(--border); display:flex; flex-direction:column; gap:8px; font-size:14px;">
                <div><b style="color:#059669">🏆 Top Veg:</b> ${p.finalVegMenu || 'N/A'}</div>
                <div><b style="color:#dc2626">🏆 Top Non-Veg:</b> ${p.finalNonVegMenu || 'N/A'}</div>
                <div><b style="color:#d97706">🏆 Top Fast:</b> ${p.finalFastMenu || 'N/A'}</div>
            </div>
            <div style="margin-top:16px; font-size:12px; color:var(--text2); text-align:right;">
                Sent to kitchen at: ${(p.sentAt && p.sentAt.toDate) ? p.sentAt.toDate().toLocaleString('en-IN') : 'N/A'}
            </div>
        </div>`;

        html += card;
    });

    if(!html) {
        html = '<div style="text-align:center;color:var(--text2);padding:20px;">No kitchen orders generated yet.</div>';
    }

    return `
    <div class="card" style="margin-bottom:20px; background:transparent; box-shadow:none; padding:0; border:none;">
        <div class="section-header">
            <div class="section-title" style="padding-left:10px;">Kitchen Orders & Analysis</div>
        </div>
        ${html}
    </div>
    `;
}

// --- Feedback ---
async function buildFeedbackHTML() {
    const messId = currentAdminData.messId;
    const pollsSnap = await getDocs(query(collection(db, 'polls'), where('messId', '==', messId)));
    const pollIds = pollsSnap.docs.map(doc => doc.id);

    let html = '';
    
    if (pollIds.length > 0) {
        const feedbackRes = await getDocs(collection(db, 'feedbacks'));
        const feedbacks = feedbackRes.docs
            .map(d => ({id: d.id, ...d.data()}))
            .filter(f => pollIds.includes(f.pollId));
            
        feedbacks.forEach(f => {
            html += `<tr>
                <td>${f.userId.substring(0,6)}...</td>
                <td>Quality: ${f.foodQuality} | Taste: ${f.taste} | Service: ${f.service}</td>
                <td><span style="font-style:italic;color:var(--text2)">"${f.comment || 'No comment'}"</span></td>
            </tr>`;
        });
    }

    if(!html) {
        html = '<tr><td colspan="3" style="text-align:center;color:var(--text2)">No feedback received yet.</td></tr>';
    }

    return `
    <div class="card">
        <div class="section-header">
            <div class="section-title">Student Feedback</div>
        </div>
        <table>
            <thead><tr><th>User ID</th><th>Ratings (Out of 5)</th><th>Comment</th></tr></thead>
            <tbody>${html}</tbody>
        </table>
    </div>
    `;
}

// --- Transactions ---
async function buildTransactionsHTML() {
    const messId = currentAdminData.messId;
    const txSnap = await getDocs(query(collection(db, 'transactions'), where('messId', '==', messId)));
    
    let html = '';
    const sortedDocs = txSnap.docs.map(d => ({id: d.id, ...d.data()})).sort((a, b) => {
        const timeA = a.timestamp?.toMillis ? a.timestamp.toMillis() : 0;
        const timeB = b.timestamp?.toMillis ? b.timestamp.toMillis() : 0;
        return timeB - timeA;
    });

    for(let trans of sortedDocs) {
        const transId = trans.id;
        
        const sUserDoc = await getDoc(doc(db, 'users', trans.studentId));
        const sUser = sUserDoc.exists() ? sUserDoc.data() : {name:'Unknown', prn:'N/A'};
        
        let actions = '';
        if (trans.paymentStatus === 'pending') {
            actions = `
                <button class="action-btn primary trans-approve" data-id="${transId}">Approve</button>
                <button class="action-btn trans-reject" data-id="${transId}" style="color:var(--red)">Reject</button>
            `;
        } else {
            actions = '<span>Processed</span>';
        }

        html += `<tr>
            <td>
                <span class="view-profile-btn" style="font-weight:600; cursor:pointer; color:var(--primary); text-decoration:underline"
                      data-name="${sUser.name || ''}"
                      data-prn="${sUser.prn || ''}"
                      data-branch="${sUser.branch || ''}"
                      data-year="${sUser.passoutYear || ''}"
                      data-hostel="${sUser.hostelName || ''}"
                      data-email="${sUser.email || ''}"
                      data-phone="${sUser.phone || ''}"
                      title="Click to view full profile">
                    ${sUser.name}
                </span><br><small style="color:var(--text2)">${sUser.prn}</small>
            </td>
            <td>₹${trans.amount}<br><small style="color:var(--text2)">${trans.paymentMode}</small></td>
            <td>${trans.transactionId || 'N/A'}</td>
            <td>${badgeHtml(trans.paymentStatus)}</td>
            <td>
                ${trans.paymentScreenshot ? `<a href="${trans.paymentScreenshot}" target="_blank" style="color:var(--primary);">View Receipt</a>` : 'No receipt'}
            </td>
            <td>${actions}</td>
        </tr>`;
    }

    if(!html) {
        html = '<tr><td colspan="6" style="text-align:center;color:var(--text2)">No transactions found.</td></tr>';
    }

    return `
    <div class="card">
        <div class="section-header" style="display:flex; justify-content:space-between; align-items:center;">
            <div class="section-title">Student Transactions</div>
            <input type="text" id="transaction-search" placeholder="Search transactions..." class="form-input" style="width: 250px; padding: 6px 12px; font-size:14px;">
        </div>
        <table>
            <thead><tr><th>Student</th><th>Amount & Mode</th><th>Transaction ID</th><th>Status</th><th>Receipt</th><th>Actions</th></tr></thead>
            <tbody id="transactions-tbody">${html}</tbody>
        </table>
    </div>
    `;
}

function setupTransactionsEvents() {
    const searchInput = document.getElementById('transaction-search');
    if(searchInput) {
        searchInput.addEventListener('input', (e) => {
            const query = e.target.value.toLowerCase();
            document.querySelectorAll('#transactions-tbody tr').forEach(row => {
                const text = row.innerText.toLowerCase();
                row.style.display = text.includes(query) ? '' : 'none';
            });
        });
    }

    document.querySelectorAll('.view-profile-btn').forEach(btn => {
        btn.addEventListener('click', (e) => window.showStudentProfile(e.target.dataset));
    });

    document.querySelectorAll('.trans-approve').forEach(btn => {
        btn.addEventListener('click', async (e) => {
            const transId = e.target.getAttribute('data-id');
            if(confirm("Approve this transaction?")) {
                try {
                    await updateDoc(doc(db, 'transactions', transId), { paymentStatus: 'completed' });
                    alert("Transaction approved!");
                    renderPage('transactions');
                } catch(err) {
                    alert("Error: " + err.message);
                }
            }
        });
    });
    
    document.querySelectorAll('.trans-reject').forEach(btn => {
        btn.addEventListener('click', async (e) => {
            const transId = e.target.getAttribute('data-id');
            if(confirm("Reject this transaction?")) {
                try {
                    await updateDoc(doc(db, 'transactions', transId), { paymentStatus: 'rejected' });
                    alert("Transaction rejected.");
                    renderPage('transactions');
                } catch(err) {
                    alert("Error: " + err.message);
                }
            }
        });
    });
}
