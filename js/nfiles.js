function basename(str) {
	return str.substr(str.lastIndexOf('/') + 1);
}

function nfiles(nfiles_name, nfiles_el, submit_el, submit_label, file_name, add_ep, edit_ep) {
	let loading = 0;

	function load_start() {
		submit_el.innerText = i_wait;
		submit_el.disabled = true;
		loading++;
	}

	function load_end() {
		loading--;
		if (!loading) {
			submit_el.innerText = _submit;
			submit_el.disabled = false;
		}
	}

	let search = nfiles_el.querySelector('a');
	let textarea = nfiles_el.querySelector('textarea');

	nfiles_el.removeChild(search);
	nfiles_el.removeChild(textarea);

	let nfiles_cont = document.createElement('div');
	nfiles_cont.classList.add('fw', 'f', '_s', 'vs', 'fic');
	nfiles_el.appendChild(nfiles_cont);

	let upload_image = document.createElement('button');
	upload_image.innerText = '📁';
	upload_image.classList.add('btn', 'round', 'ps', 'tsxl');
	upload_image.type = "button";
	nfiles_el.appendChild(upload_image);

	let file_input = document.createElement('input');
	file_input.type = 'file';
	file_input.name = file_name;
	file_input.classList.add('dn');
	file_input.multiple = true;
	nfiles_el.appendChild(file_input);

	let hidden_input = document.createElement('input');
	hidden_input.type = 'hidden';
	hidden_input.name = nfiles_name;
	nfiles_el.appendChild(hidden_input);

	let nfiles_map = {};

	function nfiles_insert(url) {
		let image = document.createElement('div');
		image.classList.add('tss', 'pxs', 'c0', 'rxs', '_s', 'f', 'fic');

		let image_link = document.createElement('a');
		const bname = basename(url);
		image_link.innerText = bname;
		image_link.href = url;
		image.appendChild(image_link);

		nfiles_map[url] = true;

		let btn = document.createElement('button');
		btn.classList.add('btn', 'round', 'pxs', 'tss', 'c15', 'cf0');
		btn.innerText = '×';
		btn.type = 'button';
		btn.onclick = function (ev) {
			const formData = new FormData();
			const noext = bname.substr(0, bname.indexOf('.'));

			formData.set('delete_' + noext, 'on');

			nfiles_cont.removeChild(image);
			delete nfiles_map[bname];

			fetch(edit_ep, {
				method: 'POST',
				data: formData,
			});
		};
		image.appendChild(btn);

		nfiles_cont.appendChild(image);
	}

	textarea.value.split('\n').filter(url => !!url).map(nfiles_insert);

	let main_form = document.querySelector('form');

	main_form.onsubmit = function() {
		file_input.disabled = true;
		hidden_input.value = Object.keys(nfiles_map).join('\n');
		console.log('final value', hidden_input.value);
	}

	upload_image.onclick = function (ev) {
		file_input.click(ev);
	};

	const _submit = submit_label;
	const i_wait = "⏱";

	file_input.onchange = function (ev) {
		let files = file_input.files;
		let formData = new FormData();

		for (const file of files)
			formData.append(file_input.name, file, file.name);

		load_start();

		fetch(add_ep, {
			method: 'POST',
			headers: {
				'Accept': 'text/plain',
			},
			body: formData,
		})
			.then(response => response.text())
			.then(data => {
				console.log('received', data);
				// TODO might have multiple images
				data.replaceAll('\r', '').split('\n')
					.filter(url => !!url)
					.map(nfiles_insert);
				load_end();
			});

		return false;
	};
}
