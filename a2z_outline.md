<!--
This site is ready to deploy on Netlify.
1. Download all files.
2. Place them in a GitHub repo or ZIP.
3. In Netlify, create a new site from Git > GitHub (or drag & drop ZIP).
-->

Generate a complete, responsive static website for “a2z pharmacy” with a high-end, modern look. Use plain HTML, CSS, and minimal JavaScript. Below is the outline of what the site must include—do not embed actual code. Let Codex determine the precise structure, styling, and scripts needed to achieve the goals described.

---

**1. File Structure**  
- `index.html`  
- `services.html`  
- `about.html`  
- `contact.html`  
- `css/styles.css`  
- `js/main.js`  
- `images/logo.png` (the provided logo)  
- `images/` (folder for any additional images or placeholders)

---

**2. Global Design and Color Palette**  
- The logo (in `images/logo.png`) uses a bold red and black. Extract those primary colors from the logo and make them the core branding colors of the site.  
- Introduce complementary neutrals (e.g., white or very light gray backgrounds, dark gray text) so that the red and black stand out without the design feeling flat or too monochrome.  
- Include one or two accent shades (for instance, a slightly lighter red for hover states and a medium gray for secondary backgrounds) to create subtle depth.  
- Choose a clean, modern sans-serif font (for example, a Google Font) and apply it consistently across all pages.  
- Maintain good contrast for readability and accessibility.  

---

**3. SEO, Metadata, Accessibility**  
- Each page should have a proper `<title>` tag reflecting its content (e.g., “a2z Pharmacy | Home”, “a2z Pharmacy | Services”, etc.).  
- Include meta tags for `charset`, `viewport`, a concise `description` mentioning “a2z Pharmacy – Prescription filling, vaccinations, telepharmacy, and more”, and relevant keywords.  
- Use semantic HTML elements (e.g., `<header>`, `<nav>`, `<main>`, `<section>`, `<article>`, `<footer>`).  
- Provide meaningful `alt` text for every image, including the logo.  
- Ensure keyboard accessibility (e.g., focus outlines on links and buttons, form controls with associated labels).  

---

**4. index.html (Home Page)**  
- **Header / Navigation**  
  - A fixed or sticky top bar featuring the logo on the left and navigation links on the right (Home, Services, About, Contact).  
  - On narrow viewports, collapse the navigation into a hamburger menu that opens a vertical list of links when toggled.  

- **Hero Section**  
  - A full-height hero area with a background image placeholder. Overlay that image with a semi-transparent layer (white or light gray) so text remains legible.  
  - Prominent headline: “Welcome to a2z Pharmacy” (use the logo’s red for emphasis on “a2z” and black for “Pharmacy”).  
  - Subheadline: “All your pharmacy needs, under one roof.”  
  - A call-to-action button labeled “View Our Services” that links to the Services page. The button should use the logo red and change to a lighter red on hover.

- **Why Choose Us Section**  
  - Three horizontally aligned “feature” blocks (stacked vertically on mobile) that highlight key differentiators:  
    1. Fast Prescription Filling  
    2. Expert Pharmacists & Telepharmacy  
    3. Free Home Delivery  
  - Each block should include a simple icon or placeholder image, a bold title, and a short descriptive sentence. Use a light background behind each feature to set them apart from the page background.

- **Featured Services Preview**  
  - Display three “spotlight” service cards (for example: Prescription Filling, Vaccinations, Online Refills).  
  - Each card contains an icon placeholder, a title, a brief description, and a “Learn More” link. The “Learn More” link should direct to the appropriate section on the Services page.  
  - On hover, each card should have a subtle visual effect (slight lift or shadow) and highlight the title in red.

- **Testimonials Slider**  
  - Include a slider or carousel of two or three sample customer testimonials.  
  - Each slide shows a quote, the customer’s name (placeholder), and optional star rating graphics.  
  - Add small navigation indicators (dots) below the quotes to show which slide is active. Allow automatic transitions every few seconds plus manual controls (e.g., clicking a dot).

- **Footer**  
  - A simple footer on a light-gray background containing:  
    - Brief contact information (address, phone, email)  
    - Social media icons (placeholders for Facebook, Twitter, Instagram, etc.)  
    - A small site map or quick-links list (Home, Services, About, Contact)  
    - A copyright notice  

---

**5. services.html (Services Page)**  
- **Hero / Banner**  
  - A full-width banner image placeholder with a semi-transparent overlay and centered title: “Our Services.”  
  - Subtitle or short intro sentence summarizing the breadth of offerings.

- **Grid of Service Cards**  
  - A responsive grid layout that adapts from multiple columns on desktop to a single column on mobile.  
  - Each card must include:  
    - An icon or image placeholder at the top (for visual identification)  
    - A service title in black (e.g., “Prescription Filling”)  
    - A one- or two-sentence description in dark gray that briefly explains what’s included.  
    - Optionally, a “Learn More” link or a button, which could expand an accordion or anchor down to more details on the same page.  
  - List every service:
    1. Prescription Filling  
    2. OTC Medications  
    3. Vaccinations (flu, shingles, travel)  
    4. Health Screenings (blood pressure, cholesterol, COVID)  
    5. Medication Reviews  
    6. COVID Screenings  
    7. Home Delivery  
    8. Online Refills  
    9. Telepharmacy Consultations  
    10. Wellness Products  
    11. Diabetic Supplies  
    12. Medical Devices  
    13. Nutritional Supplements  
    14. Travel Vaccines  
  - On hover, each card should highlight in red or gain a shadow effect.  

- **Call to Action**  
  - Below the grid, include a full-width or centered button labeled “Request a Service” in red. When clicked, it scrolls to the contact form on the Contact page.

---

**6. about.html (About Page)**  
- **Hero / Banner**  
  - A wide banner image placeholder with overlaid text. Title: “About a2z Pharmacy” (with “a2z” in red, “Pharmacy” in black).  
  - A short subtitle or tagline about the company’s mission.

- **Mission & History Section**  
  - Two-column layout on desktop (stacked on mobile):  
    - Left column: a large image placeholder (e.g., store interior, pharmacist helping a patient).  
    - Right column: a few paragraphs describing the company’s background, mission, values, and commitment to community health. Use dark-gray text on a white background.  

- **Meet Our Team**  
  - A grid or row of circular staff photos (placeholders) with each person’s name and title beneath.  
  - Use a simple border or drop shadow around each photo to keep it neat.  

- **Technology & Safety**  
  - A section that explains how a2z Pharmacy leverages modern technology (telepharmacy platform, secure systems) and follows best practices for safety, HIPAA compliance, etc.  
  - Include small icon placeholders or infographic-style visuals in red and black to illustrate each point (e.g., a shield icon for privacy, a computer screen icon for telepharmacy).

---

**7. contact.html (Contact Page)**  
- **Hero / “Get in Touch” Section**  
  - A background image placeholder (e.g., a map or a photo of the pharmacy exterior) with a semi-opaque overlay.  
  - Centered heading: “Get in Touch” in black, with “a2z Pharmacy” logo displayed at the top or near the heading.

- **Main Content Area**  
  - Two-column layout on desktop (stacked on mobile):  
    1. **Contact Form Column**  
       - A form with fields for:  
         • Name (required)  
         • Email (required, email‐type)  
         • Phone (optional)  
         • Subject (dropdown with options: Prescription, OTC/Wellness, Vaccination, Telepharmacy, Other)  
         • Message (required)  
       - A red “Submit” button that slightly changes shade on hover.  
       - Basic client-side validation: required fields must be filled, email must be formatted correctly, and show inline error messages in red if invalid.  
    2. **Contact Information Column**  
       - Physical address (street, city, state, ZIP)  
       - Phone number  
       - Business hours (e.g., Mon–Fri 9am–7pm, Sat 10am–4pm)  
       - Email address (formatted as a clickable mailto link in red)  
       - Optionally include a small static map image or an embedded map placeholder above or beside this information.

- **Footer**  
  - Same style as on the Home page: light-gray background, dark-gray text, social icons, quick links, and a copyright notice.

---

**8. css/styles.css (General Styling Guidelines)**  
- Define a set of core colors as variables or custom properties (primary red, primary black, white, light gray, dark gray, hover red) based on the logo.  
- Set a global base font (a modern sans-serif) and consistent line heights.  
- Establish responsive breakpoints (for example: mobile < 768px, tablet 768–1024px, desktop > 1024px).  
- Create a navigation bar style that:  
  - Is fixed/sticky at the top of the viewport.  
  - Displays links horizontally on larger screens, collapses to a hamburger menu on smaller screens.  
- Style all headings (H1, H2, H3, etc.) to use the primary black color, with occasional red accents for important words.  
- Design button styles that use the primary red background with white text, and transition to a lighter red on hover.  
- Implement card styles (for features, services, testimonials, team members) that:  
  - Have a clean white background, light-gray border or subtle shadow, and consistent padding.  
  - On hover, the card should slightly lift or show a stronger shadow, and key text (e.g., the title) can turn red.  
- For hero sections, use full-width background images with a semi-transparent overlay. Place text content on top, centered or aligned to one side, ensuring readability.  
- Ensure all text blocks across pages have sufficient padding/margins so the layout feels open and modern (plenty of white space).  
- Use consistent spacing (margins, paddings) throughout—define a spacing scale (e.g., small, medium, large) and apply it to sections, cards, and form fields.  
- Add subtle hover and transition effects on links, images, and interactive elements (e.g., buttons, cards).  

---

**9. js/main.js (Interactivity Requirements)**  
- Implement a toggle function for the mobile navigation menu: clicking the hamburger icon should reveal or hide the menu links.  
- Create a testimonial slider that automatically advances every few seconds, with manual controls (dots or arrows) to navigate between slides.  
- Add smooth-scroll behavior for any anchor links that point to sections on the same page (e.g., “View Our Services” scrolling down to services).  
- Provide basic client-side form validation on the Contact page to prevent submission if required fields are empty or if the email is not valid. Display inline error messages in the primary red color.  
- Any additional JavaScript needed to enhance the user experience (e.g., animating hover effects, lazy loading of images) can be determined by Codex.

---

**10. Additional Notes for Codex**  
- Reference the `images/logo.png` on every page header so the brand is consistent.  
- Use semantic and accessible markup: ensure all interactive elements (buttons, links, form controls) have appropriate ARIA attributes if needed.  
- Keep the overall design cohesive: consistent typography, consistent use of red and black for brand emphasis, and neutral backgrounds to give visual breathing room.  
- Make sure the site is fully responsive: test at least three breakpoints (mobile, tablet, desktop).  
- Organize CSS and JS into their separate files (`css/styles.css`, `js/main.js`) and link them appropriately in each HTML file.  
- Assume that placeholder images (hero backgrounds, icons, staff photos) will be replaced later—use generic `jpg` or `png` placeholders with descriptive filenames (e.g., `hero-home.jpg`, `team-jane-doe.jpg`).  
- When referring to colors, use the hex codes extracted from the logo (for example, red #C1272D and black #000000), but let Codex decide on exact usage (borders, text, backgrounds, hover states).

---

**11. Deployment Instructions (Reminder)**  
- Include a comment at the very top of the code (in each HTML file) that mentions:  
<!-- This site is ready to deploy on Netlify. 1. Download all files. 2. Place them in a GitHub repo or ZIP. 3. In Netlify, create a new site from Git > GitHub (or drag & drop ZIP). -->
- After Codex generates all the files, you should be able to save them to your local machine or commit them to GitHub. Then connect the repository (or drag & drop a ZIP) into Netlify to publish the site.
