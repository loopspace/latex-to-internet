function moveEqNums() {
    var dmaths = document.getElementsByClassName('displaymaths numbered align');
    for (var i = 0; i < dmaths.length; i++) {
	var dmath = dmaths[i];
	if (dmath.tagName == 'table')
	{
	    var rows = dmath.firstChild.childNodes[1].children[0].firstChild.firstChild.children;
	    var labels = dmath.firstChild.childNodes[2].firstChild.children;
            for (var j = 0; j < rows.length; j++) {
		labels[j].style.height = rows[j].scrollHeight + 'px';
            }
	}
    }
}

window.addEventListener('load', moveEqNums);

