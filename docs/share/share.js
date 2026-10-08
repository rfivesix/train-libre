(() => {
  'use strict';
  const title = document.getElementById('title');
  const subtitle = document.getElementById('subtitle');
  const list = document.getElementById('items');
  const actions = document.getElementById('actions');
  const codeBox = document.getElementById('code');
  const params = new URLSearchParams(location.hash.slice(1));
  const code = params.get('data');

  function invalid(error) {
    title.textContent = 'Could not preview this link';
    subtitle.textContent = error?.message === 'Browser does not support gzip'
      ? 'This browser cannot decompress the link. Open it in a current browser or in Train Libre.'
      : 'The link is incomplete, damaged, or uses an unsupported format.';
  }

  async function decode() {
    if (!code || code.length > 16000 || !/^[A-Za-z0-9_-]+$/.test(code)) {
      throw Error('Invalid code');
    }
    const normalized = code.replace(/-/g, '+').replace(/_/g, '/');
    const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '=');
    const compressed = Uint8Array.from(atob(padded), c => c.charCodeAt(0));
    if (typeof DecompressionStream === 'undefined') throw Error('Browser does not support gzip');
    const stream = new Blob([compressed]).stream().pipeThrough(new DecompressionStream('gzip'));
    const reader = stream.getReader();
    const chunks = [];
    let length = 0;
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      length += value.length;
      if (length > 128 * 1024) throw Error('Payload too large');
      chunks.push(value);
    }
    const bytes = new Uint8Array(length);
    let offset = 0;
    for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
    const payload = JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
    if (payload.v !== 1 || !['routine', 'plan', 'recipe'].includes(payload.t) ||
        typeof payload.n !== 'string' || !payload.n.trim() ||
        !payload.d || typeof payload.d !== 'object') throw Error('Unsupported content');
    return payload;
  }

  function line(text) {
    const item = document.createElement('li');
    item.textContent = text;
    list.appendChild(item);
  }

  decode().then(payload => {
    title.textContent = payload.n;
    const data = payload.d;
    if (payload.t === 'routine') {
      if (!Array.isArray(data.exercises)) throw Error('Invalid routine');
      subtitle.textContent = `Routine · ${data.exercises.length} exercises`;
      data.exercises.slice(0, 100).forEach(exercise =>
        line(`${exercise.name || 'Exercise'} · ${(exercise.sets || []).length} sets`));
    } else if (payload.t === 'plan') {
      if (!Array.isArray(data.days)) throw Error('Invalid plan');
      subtitle.textContent = `Training plan · ${data.days.length} days`;
      data.days.slice(0, 14).forEach((day, index) =>
        line(`${index + 1}. ${day ? day.n || 'Routine' : 'Rest day'}`));
    } else {
      if (!Array.isArray(data.items)) throw Error('Invalid recipe');
      const total = key => data.items.reduce((sum, item) =>
        sum + (Number(item[key]) || 0) * (Number(item.grams) || 0) / 100, 0);
      const portions = Number.isInteger(data.portions) && data.portions > 0 ? data.portions : 1;
      subtitle.textContent = `Recipe · ${portions} portion(s) · ${data.items.length} ingredients · ${Math.round(total('kcal'))} kcal · P ${Math.round(total('protein'))} g · C ${Math.round(total('carbs'))} g · F ${Math.round(total('fat'))} g`;
      data.items.slice(0, 100).forEach(item =>
        line(`${item.name || 'Ingredient'} · ${item.grams || 0} ${item.unit === 'ml' ? 'ml' : 'g'}`));
    }
    list.hidden = false;
    actions.hidden = false;
    codeBox.hidden = false;
    codeBox.textContent = `Share link: ${location.href}`;
    document.getElementById('open-app').href = `trainlibre://share#data=${code}`;
    document.getElementById('copy-code').addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(location.href);
        document.getElementById('copy-code').textContent = 'Copied';
      } catch {
        document.getElementById('copy-code').textContent = 'Select the link below to copy';
      }
    });
  }).catch(invalid);
})();
