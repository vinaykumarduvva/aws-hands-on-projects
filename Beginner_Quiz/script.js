document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('quiz-form');
    const submitBtn = document.getElementById('submit-btn');

    // Create success message element
    const successMsg = document.createElement('div');
    successMsg.className = 'success-message';
    successMsg.innerHTML = `
        <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round" class="css-i6dzq1"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>
        Answers saved locally!
    `;
    document.body.appendChild(successMsg);

    form.addEventListener('submit', (e) => {
        e.preventDefault();
        
        // Button animation
        const originalText = submitBtn.innerHTML;
        submitBtn.innerHTML = `
            <span>Saving Answers...</span>
            <svg class="animate-spin" viewBox="0 0 24 24" width="20" height="20" stroke="currentColor" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="2" x2="12" y2="6"></line><line x1="12" y1="18" x2="12" y2="22"></line><line x1="4.93" y1="4.93" x2="7.76" y2="7.76"></line><line x1="16.24" y1="16.24" x2="19.07" y2="19.07"></line><line x1="2" y1="12" x2="6" y2="12"></line><line x1="18" y1="12" x2="22" y2="12"></line><line x1="4.93" y1="19.07" x2="7.76" y2="16.24"></line><line x1="16.24" y1="7.76" x2="19.07" y2="4.93"></line></svg>
        `;
        
        // Add spin animation via CSS dynamically if not present
        if (!document.getElementById('spin-style')) {
            const style = document.createElement('style');
            style.id = 'spin-style';
            style.innerHTML = `
                @keyframes spin { 100% { transform: rotate(360deg); } }
                .animate-spin { animation: spin 1s linear infinite; }
            `;
            document.head.appendChild(style);
        }

        // Simulate a brief save operation
        setTimeout(() => {
            submitBtn.innerHTML = originalText;
            
            // Show success toast
            successMsg.classList.add('show');
            
            // Save to localStorage so answers persist across reloads
            const formData = new FormData(form);
            const answers = {};
            formData.forEach((value, key) => {
                answers[key] = value;
            });
            localStorage.setItem('aws_beginner_quiz_answers', JSON.stringify(answers));

            setTimeout(() => {
                successMsg.classList.remove('show');
            }, 3000);
        }, 1000);
    });

    // Load saved answers if any exist
    const savedAnswers = localStorage.getItem('aws_beginner_quiz_answers');
    if (savedAnswers) {
        const answers = JSON.parse(savedAnswers);
        for (const [key, value] of Object.entries(answers)) {
            const input = document.getElementById(key);
            if (input) {
                input.value = value;
            }
        }
    }
});
