(() => {
    const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'notbad-rockstar-editor';
    const $ = (id) => document.getElementById(id);

    const el = {
        indicator: $('indicator'),
        label: $('indicator-label'),
        time: $('indicator-time'),
        menu: $('menu'),
        status: $('menu-status'),
        toasts: $('toasts'),
        flash: $('flash'),
    };
    const buttons = {};
    document.querySelectorAll('#menu button[data-action]').forEach((b) => { buttons[b.dataset.action] = b; });

    let strings = {};
    let indicator = { enabled: true, position: 'top-right', showTimer: true };
    let state = { mode: false, cinematic: false };
    let startedAt = 0;
    let confirmTimer = null;
    let escrow = [];
    let tools = [];
    let escrowBeforeEditor = true;

    const t = (key) => strings[key] || key;

    function post(name, data) {
        return fetch(`https://${resource}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {}),
        }).then((r) => r.json()).catch(() => ({}));
    }

    function clock() {
        const s = Math.max(0, Math.floor((Date.now() - startedAt) / 1000));
        const pad = (n) => String(n).padStart(2, '0');
        const h = Math.floor(s / 3600);
        return (h ? pad(h) + ':' : '') + pad(Math.floor(s / 60) % 60) + ':' + pad(s % 60);
    }

    function resetConfirm() {
        clearTimeout(confirmTimer);
        confirmTimer = null;
        buttons.editor.classList.remove('confirm');
        buttons.editor.querySelector('.label').textContent = t('ui_editor');
    }

    function render() {
        const { mode, cinematic } = state;
        const timed = mode === 'record';

        // badge
        el.indicator.hidden = !indicator.enabled || !mode;
        el.indicator.classList.toggle('replay', mode === 'replay');
        el.label.textContent = mode === 'replay' ? t('ui_replay') : t('ui_rec');
        el.time.textContent = timed && indicator.showTimer ? clock() : '';

        document.body.classList.toggle('cinematic', !!cinematic);

        // menu
        el.status.className = mode || '';
        el.status.textContent = mode === 'record' ? `${t('ui_rec')} ${clock()}`
            : mode === 'replay' ? t('ui_replay_off')
            : '';
        el.status.hidden = !mode;

        const set = (name, label, on, disabled) => {
            const b = buttons[name];
            b.querySelector('.label').textContent = label;
            b.classList.toggle('on', !!on);
            b.disabled = !!disabled;
        };
        set('toggle', mode === 'record' ? t('ui_record_stop') : t('ui_record_start'), mode === 'record');
        set('discard', t('ui_discard'), false, mode !== 'record');
        set('replay', mode === 'replay' ? t('ui_replay_off') : t('ui_replay_on'), mode === 'replay', mode === 'record');
        set('saveReplay', t('ui_save_replay'), false, mode !== 'replay');
        set('picture', t('ui_picture'));
        set('cinematic', t('ui_cinematic'), cinematic);
        if (!confirmTimer) set('editor', t('ui_editor'));
    }

    function toast(text, kind) {
        const node = document.createElement('div');
        node.className = `toast ${kind || 'info'}`;
        node.textContent = text;
        el.toasts.appendChild(node);
        while (el.toasts.children.length > 3) el.toasts.firstChild.remove();
        const life = kind === 'warning' ? 8000 : 3600;
        setTimeout(() => node.classList.add('out'), life);
        setTimeout(() => node.remove(), life + 300);
    }

    function copy(text) {
        const area = document.createElement('textarea');
        area.value = text;
        document.body.appendChild(area);
        area.select();
        try { document.execCommand('copy'); } catch (e) { /* clipboard not available */ }
        area.remove();
    }

    function visibleButtons() {
        return [...el.menu.querySelectorAll('button')].filter((b) => !b.disabled && b.offsetParent !== null);
    }

    // editorMode: the player is on the way to the editor, so offer to continue from here
    function showView(name, editorMode) {
        const escrowView = name === 'escrow' && escrow.length > 0;
        $('view-main').hidden = escrowView;
        $('view-escrow').hidden = !escrowView;
        document.querySelector('[data-local="proceed"]').hidden = !(escrowView && editorMode);
        const first = visibleButtons()[0];
        if (first) first.focus();
    }

    function renderEscrow() {
        const row = buttons.escrow;
        row.hidden = escrow.length === 0;
        row.querySelector('.label').textContent = t('ui_escrow_row');
        row.querySelector('kbd').textContent = escrow.length || '';

        $('escrow-title').textContent = t('ui_escrow_title');
        $('escrow-text').textContent = t('ui_escrow_text');
        $('escrow-list-title').textContent = t('ui_escrow_list');
        $('escrow-count').textContent = `(${escrow.length})`;
        $('escrow-legend').textContent = t('ui_escrow_legend');
        $('escrow-legend').hidden = !escrow.some((r) => r.assets);
        document.querySelector('[data-local="copy"] .label').textContent = t('ui_escrow_copy');
        document.querySelector('[data-local="back"] .label').textContent = t('ui_back');
        document.querySelector('[data-local="proceed"] .label').textContent = t('ui_escrow_proceed');

        const list = $('escrow-list');
        list.textContent = '';
        escrow.forEach((r) => {
            const li = document.createElement('li');
            li.textContent = r.name;
            if (r.assets) li.className = 'assets';
            list.appendChild(li);
        });

        const box = $('escrow-tools');
        box.textContent = '';
        box.hidden = tools.length === 0;
        tools.forEach((tool) => {
            const b = document.createElement('button');
            b.dataset.url = tool.url;
            const label = document.createElement('span');
            label.className = 'label';
            label.textContent = tool.name;
            const hint = document.createElement('kbd');
            hint.textContent = t('ui_open');
            b.append(label, hint);
            box.appendChild(b);
        });

        if (escrow.length === 0 && !$('view-escrow').hidden) showView('main');
    }

    function openMenu(open, view) {
        el.menu.hidden = !open;
        resetConfirm();
        if (open) showView(view === 'escrow-editor' ? 'escrow' : (view || 'main'), view === 'escrow-editor');
    }

    // ---- messages from the game ----
    window.addEventListener('message', ({ data }) => {
        if (!data || !data.action) return;

        if (data.action === 'state') {
            state = { mode: data.mode || false, cinematic: !!data.cinematic };
            startedAt = Date.now() - (data.elapsed || 0);
            render();
        } else if (data.action === 'toast') {
            toast(data.text, data.kind);
        } else if (data.action === 'menu') {
            openMenu(!!data.open, data.view);
        } else if (data.action === 'escrow') {
            escrow = Array.isArray(data.list) ? data.list : [];
            renderEscrow();
        } else if (data.action === 'shot') {
            document.body.classList.toggle('shot', data.phase === 'hide');
            if (data.phase === 'show' && data.flash) {
                el.flash.classList.remove('go');
                void el.flash.offsetWidth;
                el.flash.classList.add('go');
            }
        }
    });

    // ---- menu input ----
    el.menu.addEventListener('click', (e) => {
        const b = e.target.closest('button');
        if (!b || b.disabled) return;
        const name = b.dataset.action;

        if (b.dataset.url) {
            copy(b.dataset.url);
            toast(t('ui_link_copied'), 'success');
            return;
        }
        if (b.dataset.local === 'copy') {
            copy(escrow.map((r) => r.name).join('\n'));
            toast(t('ui_escrow_copied'), 'success');
            return;
        }
        if (b.dataset.local === 'back') { showView('main'); return; }
        if (b.dataset.local === 'proceed') { post('action', { name: 'editor' }); return; }
        if (name === 'editor' && escrowBeforeEditor && escrow.length > 0) { resetConfirm(); showView('escrow', true); return; }
        if (name === 'escrow') { resetConfirm(); showView('escrow'); return; }

        if (name === 'editor' && !confirmTimer) {
            b.classList.add('confirm');
            b.querySelector('.label').textContent = t('ui_editor_confirm');
            confirmTimer = setTimeout(resetConfirm, 5000);
            return;
        }
        if (name !== 'editor') resetConfirm();
        post('action', { name });
    });

    window.addEventListener('keydown', (e) => {
        if (el.menu.hidden) return;
        if (e.key === 'Escape') {
            post('close');
        } else if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
            e.preventDefault();
            const list = visibleButtons();
            const i = list.indexOf(document.activeElement);
            const next = (i + (e.key === 'ArrowDown' ? 1 : -1) + list.length) % list.length;
            list[next].focus();
        }
    });

    setInterval(() => { if (state.mode === 'record') render(); }, 500);

    // ---- boot ----
    post('ready').then((cfg) => {
        strings = cfg.strings || {};
        indicator = Object.assign(indicator, cfg.indicator || {});
        el.indicator.className = indicator.position || 'top-right';

        const cine = cfg.cinematic || {};
        document.body.classList.toggle('bars', cine.bars !== false);
        if (cine.barHeight) document.documentElement.style.setProperty('--bar-h', cine.barHeight + 'vh');

        const commands = cfg.commands || {};
        const map = { toggle: 'toggle', discard: 'record', replay: 'replay', saveReplay: 'saveReplay', picture: 'picture', cinematic: 'cinematic', editor: 'editor' };
        Object.entries(map).forEach(([action, id]) => {
            const cmd = commands[id];
            buttons[action].querySelector('kbd').textContent = cmd ? `/${cmd}${action === 'discard' ? ' discard' : ''}` : '';
        });

        $('menu-title').textContent = t('title');
        $('menu-hint').textContent = t('ui_hint');
        tools = Array.isArray(cfg.tools) ? cfg.tools : [];
        escrowBeforeEditor = cfg.escrowBeforeEditor !== false;
        render();
        renderEscrow();
    });
})();
