(() => {
   document.addEventListener('DOMContentLoaded', function () {
      const textarea = document.querySelector('.checkout-card textarea#customerComment');
      if (textarea) {
         textarea.rows = 8;
      }
   });
})();
