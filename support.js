/* global document, URLSearchParams, window */

const form = document.querySelector('#support-form');

form.addEventListener('submit', (event) => {
  event.preventDefault();
  if (!form.reportValidity()) return;

  const subject = document.querySelector('#subject').value.trim();
  const message = document.querySelector('#message').value.trim();
  const query = new URLSearchParams({
    to: 'support@support-electricel.com',
    subject,
    body: message,
  });
  window.location.href = `https://outlook.office.com/mail/deeplink/compose?${query}`;
});
