<!doctype html>
<html>
	<head>
		<meta http-equiv="content-type" content="text/html; charset=utf-8;" />
		<title>{{PAGE_TITLE}} - {{TITLE}}</title>

		<link rel="stylesheet" href="/theme/css/style.css" type="text/css" media="screen" />
		<script src="/theme/js/jquery.js"></script>
		<script src="/theme/js/utils.js"></script>
	</head>
	<body class="{{PAGE_URI:dashed}}">
		<div class="tooltip"></div>

<div class="sidebar">
	<div class="outline">
		<div class="block left">
			<div class="header">Манга</div>
			<ul>
				<li><a href="/manga">Список</a></li>
				<li><a href="/manga/add">Добавить</a></li>
				<li><a href="/import">Импорт</a></li>
				<li><a href="/statistics">Статистика</a></li>
			</ul>
		</div>
		<div class="block middle">
			<div class="header">Настройки</div>
			<ul>
				<li><a href="/log">Логи</a></li>
				<li><a href="/manga/filters">Фильтр жанров</a></li>
				<li><a href="/sql">SQL</a></li>
			</ul>
		</div>
		<div class="block right">
			<div class="header">Система</div>
			<ul>
				<li><a href="/static/about">О программе</a></li>
				<li><a href="/quit">Выход</a></li>
			</ul>
		</div>
		<div class="block right">
{{nav:empty}}
		</div>
	</div>
</div>

		<div class="platesholder">
			<div class="plates">
{{CONTENT}}
			</div>
		</div>
	</body>
</html>