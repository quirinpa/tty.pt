function menu(cont_el) {
	let menu_el = cont_el.querySelector('div');
	cont_el.classList.add("js");
	cont_el.removeChild(cont_el.querySelector("input"));
	menu_el.classList.add("dn");
	let sem_menu_visible = false;
	cont_el.onclick = function (ev) {
		sem_menu_visible = !sem_menu_visible;
		if (sem_menu_visible)
			menu_el.classList.remove("dn");
		else
			menu_el.classList.add("dn");
	};
}
