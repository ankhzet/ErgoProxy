<!doctype html>
<html>
	<head>
		<meta http-equiv="content-type" content="text/html; charset=utf-8;" />
		<title>{{TITLE}}</title>
		<style>
			body {
				background-color: #eef;
				margin: 5px 2%;
				width: 96%;
				font: 16px/24px Tahoma;
			}

			.right {
				float: right;
			}
			.jenres-list {
				color: navy;
				font-size: 90%;
			}
			.jenres {
				font-weight: normal;
			}

			.jenres-list.top {
				color: navy;
				font-weight: bold;
				padding: 2px 5px;
				border: 1px solid #ccd;
			}

			.manga-list {
				width: 90%;
				margin: 25px auto;
			}

			.manga-list h4 {
				margin: 0 10px;
				padding: 2px 5px;
			}

			.manga-list .manga {
				margin: 0 10px;
				min-height: 150px;
			}
			.manga-list .manga-data>* {
				padding: 2px 5px;
				padding-left: 120px;
			}

			.manga-list .manga img {
				float: left;
				width: 100px;
				height: 150px;
				border: none;
				outline: none;
			}

			.manga-list .manga .title {
				margin: 15px 0 0 0;
				background-color: #dedeef;
				font-weight: bold;
				text-shadow: 0 1px 1px white;
				color: green;
				font-size: 110%;
			}

			.manga-list .manga .description {
				color: black;
			}

			.manga-list .manga a {
				margin: 5px 0 0 0;
				font-size: 90%;
				color: blue;
			}

			.manga-list-separator {
				border: 0;
				border-bottom: 1px solid white;
				border-top: 1px solid #ccd;
			}
		</style>
	</head>
	<body>
		<div class="jenres-list top">Jenres: <span class="jenres">{{JENRES}}</span><span class="right">{{TITLE}}</span></div>
		<div class="manga-list">
			{{LIST}}
		</div>
	</body>
</html>