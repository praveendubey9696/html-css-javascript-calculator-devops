// Simple client-side calculator logic
const display = document.getElementById('display');
let current = '';
let operator = null;
let prev = null;

function updateDisplay(v){ display.value = v; }

document.querySelectorAll('.keys button').forEach(btn=>{
  btn.addEventListener('click', ()=> {
    const v = btn.dataset.value;
    const op = btn.dataset.op;
    if (btn.id === 'clear') {
      current = ''; operator = null; prev = null; updateDisplay('');
      return;
    }
    if (btn.id === 'equals') {
      try {
        const res = eval(display.value.replace('×','*').replace('÷','/'));
        updateDisplay(res);
      } catch(e) {
        updateDisplay('Error');
        console.error(e);
      }
      return;
    }
    if (v !== undefined) {
      current += v;
      updateDisplay(current);
      return;
    }
    if (op !== undefined) {
      current += op;
      updateDisplay(current);
    }
  });
});
