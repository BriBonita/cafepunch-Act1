// ─── Mobile menu ────────────────────────────────────────
const hamburger = document.getElementById('hamburger');
const navList = document.getElementById('nav-list');

if (hamburger && navList) {
  hamburger.addEventListener('click', () => {
    hamburger.classList.toggle('open');
    navList.classList.toggle('open');
  });

  // Dropdown toggle on mobile tap
  document.querySelectorAll('.nav-item.has-dropdown > a').forEach(link => {
    link.addEventListener('click', (e) => {
      if (window.innerWidth <= 768) {
        e.preventDefault();
        const item = link.parentElement;
        item.classList.toggle('open');
      }
    });
  });
}

// ─── Newsletter ──────────────────────────────────────────
function handleNewsletter(e) {
  e.preventDefault();
  const input = e.target.querySelector('input');
  alert(`¡Gracias! Te hemos suscrito con: ${input.value}`);
  input.value = '';
}

// ─── Cart state ──────────────────────────────────────────
let cartCount = 0;
let cartTotal = 0;

const cartBtn = document.querySelector('.btn-cart');

function updateCart(price = 0) {
  cartCount++;
  cartTotal += price;
  if (cartBtn) {
    cartBtn.innerHTML = `<i class="fa-solid fa-cart-shopping"></i> $${cartTotal.toFixed(0)} MXN (${cartCount})`;
  }
}


