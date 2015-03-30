<div id="cacheholder">
	<div id="cache">
		<div class="no-scans">
			No scans (maybe last of available chapters?)
		</div>
	</div>
	<div class="pages">Page: <span id="pagen">0</span>/<span id="pagec">0</span></div>
	<div class="magnifier"><div class="m-inner"></div><img></div>
</div>
<style>

.sidebar {
	height: auto;
	position: absolute;
	width: 120px;
	margin: -6px 0 0 10px;
	padding-top: 5px;
	border: 1px solid black;
	border-right: 0;
	border-top: 0;
	border-radius: 5px;
}
.sidebar .block {
	width: 400%;
	clear: both;
	font-size: 10px;
}
.sidebar .block * {
	width: 400%;
	text-align: left;
}

.sidebar .block.left li:before,
.sidebar .block.left li:after,
.sidebar .block.right li:before,
.sidebar .block.right li:after
{
	content: '';
}

#cacheholder #cache img {
	max-width: 100%;
	max-height: {{view.height}}px;
	margin: 0;
	border: 1px solid #88e;
	border-radius: 3px;
}

</style>

<script src="/theme/js/magnifier.js"></script>
<script>

$('.fs').click(function(){fullscreen($(this))});

function fullscreen(src) {
	var body = $('body'), cache = $('#cache');

	fs = !src.attr('isfullscreen');
	if (fs) {
		var div = $('<div class="fullscreen"><a class="fs f" href="javascript:void(0)">FS</a></div>');
		div.append(cache);
		cache.css({'width': '100%', 'height': '100%'});
		body.append(div);
		$('.fs.f').click(function(){fullscreen($(this))});
		$('#cache img').height(body.height());
	} else {
		$('#cacheholder').append(cache);
		$('.fullscreen').remove();
		var p = $('.pages');
		p.remove();
		$('#cacheholder').append(p);
	}
	$('.fs').attr('isfullscreen', fs ? true : null);
}

function locate(chapter, delta) {
	var location = '/reader/{{manga.root}}/' + ((chapter > 0) ? '/' + chapter : '');
	var params = [];
	if ($('.fs').hasClass('f')) params.push('fullscreen=1');
	if (delta) params.push('delta=' + delta);
	if (params.length) location += '?' + params.join('&');
	document.location = location;
}

$('.prev').click(function() { locate({{manga.chapter.id}},-1); });
$('.next').click(function() { locate({{manga.chapter.id}}, 1); });

$(function(){
	var chapter = {
		manga_id: "{{manga.id}}",
		manga: {{manga.titles:json}},
		chapter: {{manga.chapter.id}},
		page: parseInt((m = document.location.hash.match(/page(\d+)/i)) ? m[1] : {{manga.page_id}}),
		downloaded: {{manga.is_downloaded:bool}},
		manhwa: {{manga.is_webtoon:bool}},
		original : false,
		root: "/manga/{{manga.root}}/{{manga.chapter.id:chapter}}/",
		pages: {{manga.scans:json}},
		holder: $('#cache'),

		scan_to: function(delta) {
			var nextPage = this.page + delta;
			var prev = $('#page' + this.page);
			var next = $('#page' + nextPage);
			var nextOnNextChapter = (this.manhwa && (!!delta)) || (nextPage < 1) || (nextPage > this.pages.length);
			var noNeedToLoad = (!!next.length) || nextOnNextChapter;
			if (!noNeedToLoad) {
				this.onload($('#cache img').length ? this.page : 0);
				return;
			}
			if (!nextOnNextChapter) {
				if (!this.manhwa && prev) $(prev).hide();
				if (!this.manhwa && next) $(next).show();
				this.page += delta;
				$AJAX('/progress/{{manga.root}}/{{manga.chapter.id}}/' + this.page, {});
				this.scan_num(this.page);
			} else
				locate({{manga.chapter.id}}, delta);
		},

		scan_prev: function () { this.scan_to(-1); },
		scan_next: function () { this.scan_to(1); },

		scan_num: function (scan) {
		$('#pagen').text(chapter.page);
//			document.location.hash = "#page" + scan;
//			if (this.manhwa)
//				$(document).scrollTop($('#page' + scan).offset().top);
		},

		onload: function (idx) {
			if (this.timers)
				for (var i in this.timers)
					clearTimeout(this.timers[i]);

			var src = this.pages[idx];
			if (!src) {
				if (getParams()['fullscreen'])
					fullscreen($('.fs'));
				return;
			}
			var a = $('<a id="page' + (idx + 1) + '">');
			var show = this.manhwa || (this.page ? (this.page == idx + 1) : !idx);
			a.toggle(show);
			if (show)
				this.scan_num(idx + 1);

			if (src.match(/\.pdf$/ig)) {
//				document.location = this.root + src;
				var img = $('<a>');
				img.attr('href', this.root + src);
				img.html('<br />' + this.root + src);
//				img.style = "width: 100%; height: 100%";
			} else {
				var img = $('<IMG>');
			}
			if (document.location.hash.match(/rnd/i))
				src += '?rand=' + Math.random();
			img.attr('src', this.root + src);
			img.attr('idx', idx);
			img.load(function () {
				var cc = chapter.pages.length;
				$('#pagec').text(((idx + 1) == cc) ? cc : (idx + 1) + ' (' + cc + ')');
				chapter.onload(idx + 1);
			});
			this.timers = this.timers || [];
			this.timers[idx] = setTimeout(function() {chapter.failed()}, 10000);
			this.loading = [idx + 1, img];
			a.append($('<a name="page' + (idx + 1) + '" />'));
			a.append(img);
			if (!(this.pages[idx + 1] && this.manhwa)) {
				a.click(function() {chapter.scan_next()});
				img.css('cursor', 'pointer');
			}
			magnifier.handle(img);
			this.holder.append(a);
		},
		failed: function() {
			this.onload(this.loading[0]);
		},

		load: function() {
			if (this.manhwa) {
				this.holder.addClass("manhwa");
				this.page = this.pages.length;
			}

			if (!this.pages.length) {
				$('.nav.bottom, .pages').hide();
				$('.no-scans').show();
			} else
				this.scan_to(0);

			$('.preview').click(function() {
				var page = chapter.root + chapter.pages[chapter.page - 1];
				document.location = '/preview/{{manga.root}}?origin=' + page;
			});

			$(window).keydown(function(event) {
				switch (event.keyCode) {
				case 37: // Left
					chapter.scan_prev(this);
					break;
				case 39: // Right
					chapter.scan_next(this);
					break;
				case 70: // f
//					fullscreen($('.fs'));
					break;
				}
			});
		}

	}
	$(function() {
		chapter.load();
	});
});

</script>
