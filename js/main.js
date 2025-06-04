// Toggle mobile navigation
const hamburger = document.querySelector('.hamburger');
const navLinks = document.querySelector('nav ul');
if (hamburger) {
  hamburger.addEventListener('click', () => {
    navLinks.classList.toggle('show');
  });
}

// Testimonial slider
let currentSlide = 0;
const slides = document.querySelectorAll('.testimonial-slide');
const dots = document.querySelectorAll('.dot');
function showSlide(index) {
  slides.forEach((slide, i) => {
    slide.style.display = i === index ? 'block' : 'none';
    if (dots[i]) dots[i].classList.toggle('active', i === index);
  });
  currentSlide = index;
}
function nextSlide() {
  const index = (currentSlide + 1) % slides.length;
  showSlide(index);
}
if (slides.length) {
  showSlide(0);
  setInterval(nextSlide, 5000);
  dots.forEach((dot, i) => dot.addEventListener('click', () => showSlide(i)));
}

// Smooth scroll for anchor links
const anchors = document.querySelectorAll('a[href^="#"]');
anchors.forEach(anchor => {
  anchor.addEventListener('click', function(e) {
    const targetId = this.getAttribute('href').substring(1);
    const target = document.getElementById(targetId);
    if (target) {
      e.preventDefault();
      target.scrollIntoView({ behavior: 'smooth' });
    }
  });
});

// Contact form validation
const contactForm = document.querySelector('#contact-form');
if (contactForm) {
  contactForm.addEventListener('submit', function(e) {
    let valid = true;
    const required = this.querySelectorAll('[required]');
    required.forEach(field => {
      const error = field.nextElementSibling;
      if (!field.value.trim() || (field.type === 'email' && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(field.value))) {
        valid = false;
        if (error) error.textContent = 'Please enter a valid ' + field.name;
      } else if (error) {
        error.textContent = '';
      }
    });
    if (!valid) e.preventDefault();
  });
}
