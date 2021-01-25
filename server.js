const express = require('express');
const app = express();
const axios = require('axios');
const cors = require('cors');
const googleTrends = require('google-trends-api');

const guardianKey = '';
const nytimesKey = '';

const guardianDefaultImg = 'https://assets.guim.co.uk/images/eada8aa27c12fe2d5afa3a89d3fbae0d/fallback-logo.png';
const nytimesDefaultImg = 'https://upload.wikimedia.org/wikipedia/commons/0/0e/Nytimes_hq.jpg';

app.use(cors());

app.get('/trend', (req, res) => {
	var keyword = req.query.keyword;
	googleTrends.interestOverTime({keyword: keyword, startTime: new Date('2019-06-01')})
	.then(function(results){
		var json = JSON.parse(results)
		var values = []
	 	 for (var result of json["default"]["timelineData"]) {
	 	 	// console.log(result["value"])
	 	 	values.push(result["value"][0])
	 	 }
	 	 console.log(values)
	 	 res.json(values)
	})
	.catch(function(err){
	  console.error('Oh no there was an error', err);
	});
})


// Guardian section API doesn't response with blocks??
app.get('/guardian', (req, res) => {
	var section = req.query.section;
	var isSearch = false;
	var url;
	if (section == "sports") {
	 	section = "sport";
	}
	if (section == 'home') {
		url = 'https://content.guardianapis.com/search?api-key=' +
		guardianKey + '&section=(sport|business|technology|politics)&show-blocks=all';
	} else if (section == 'search') {
		var keyword = req.query.keyword;
		url = 'https://content.guardianapis.com/search?q=' + keyword +
	 '&api-key=' + guardianKey + '&show-blocks=all';
	 isSearch = true;
	} else {
		url = 'https://content.guardianapis.com/' + section + '?api-key=' +
		guardianKey + '&show-blocks=all';
	}
	var guardianNews = [];

	console.log("guardian: " + url)
	axios.get(url)
	.then(function (response) {
		var results = response.data.response.results;

		for (var result of results) {
			if (result.webTitle && result.sectionId && result.webPublicationDate &&
				result.webUrl && result.id && result.blocks && result.blocks.body &&
				result.blocks.body[0] && result.blocks.body[0].bodyTextSummary) {

				var news = {};
				news['title'] = result.webTitle;
				news['image'] = "";
				if (result.blocks.main && result.blocks.main.elements &&
					result.blocks.main.elements[0] &&
					result.blocks.main.elements[0].assets) {

					var assets = result.blocks.main.elements[0].assets;
					var lastIdx = assets.length - 1;
					if (lastIdx != -1 && assets[lastIdx].file) {
						news['image'] = assets[lastIdx].file;
					}
				}
				news['section'] = result.sectionId;
				news['date'] = result.webPublicationDate;
				if (!isSearch) {
					news['description'] = result.blocks.body[0].bodyTextSummary;
				}
				news['sharelink'] = result.webUrl;
				news['id'] = result.id;
				news['com'] = "guardian";
				guardianNews.push(news);
				if (guardianNews.length == 10) {
					break;
				}
			}
		}
    res.json(guardianNews);
	})
	.catch(function (error) {
		if (!error.reponse) {
			console.log(error);
			return;
		}
		console.log(error.response.data);
		if (error.response.data.response) {
			res.json({'error': error.response.data.response.message});
		} else if (error.response.data.message) {
			res.json({'error': error.response.data.message});
		} else if (error.response.data) {
			res.json({'error': error.response.data});
		}
	});
});

app.get('/nytimes', (req, res) => {

	var section = req.query.section;
	var url;
	if (section == 'home') {
		url = 'https://api.nytimes.com/svc/topstories/v2/home.json?api-key=' +
		nytimesKey;
	} else {
		url = 'https://api.nytimes.com/svc/topstories/v2/' + section +
		'.json?api-key=' + nytimesKey;
	}
	var nytimesNews = [];

	axios.get(url)
	.then(function (response) {

		var results = response.data.results;

		for (result of results) {

			var news = {};

			if (result.title && result.section && result.published_date &&
				result.abstract && result.url) {

				news['title'] = result.title;
				news['image'] = nytimesDefaultImg;

				if (result.multimedia) {
					for (var i = 0; i < result.multimedia.length; i++) {
						var media = result.multimedia[i];
						if (media.url && media.width >= 2000) {
							news['image'] = media.url;
							break;
						}
					}
				}

				news['section'] = result.section;
				news['date'] = result.published_date.substr;
				news['description'] = result.abstract;
				news['sharelink'] = result.url;
				news['id'] = result.url;
				news['com'] = "nytimes";
				nytimesNews.push(news);
				if (nytimesNews.length == 10) {
					break;
				}
			}
		}
    res.json(nytimesNews);
	})
	.catch(function (error) {
		if (error.response.data.fault) {
			res.json({'error': error.response.data.fault.faultstring});
		} else if (error.response.data) {
			res.json({'error': error.response.data});
		}
	});
});

app.get('/details/guardian', (req, res) => {
	var id = req.query.id;
	var url = 'https://content.guardianapis.com/' + id + '?api-key=' +
	 guardianKey + '&show-blocks=all';
	var details = {};
	console.log(url)
	axios.get(url)
	.then(function (response){

		var content = response.data.response.content;

		if (content.webTitle && content.webPublicationDate && content.webUrl &&
			content.blocks && content.blocks.body && content.blocks.body) {

			details['title'] = content.webTitle;
			details['image'] = "";

			if (content.blocks && content.blocks.main &&
				content.blocks.main.elements && content.blocks.main.elements[0] &&
				content.blocks.main.elements[0].assets) {
				var assets = content.blocks.main.elements[0].assets;
				var lastIdx = assets.length - 1;
				if (lastIdx >= 0 && assets[lastIdx].file) {
					details['image'] = assets[lastIdx].file;
				}
			}
			details['date'] = content.webPublicationDate.substr(0, 20);
			var description = ""
			for (body of content.blocks.body) {
				if (body.bodyHtml) {
					description += body.bodyHtml;
				}
			}
			description.replace(/<iframe>.*<\/iframe>/g, "");
			details['description'] = description

			console.log(description)
			details['sharelink'] = content.webUrl;
			details['section'] = content.sectionName;
       		details['com'] = "guardian";
		} else {
			// ??? what if there is missing data for detail page
		}

	}).catch(function (error){
		console.log(error);
		details['error'] = error.response.data.message;
	}).then(function(){
		res.json(details);
	});

});

app.get('/details/nytimes', (req, res) => {
	var id = req.query.id;
	var url = 'https://api.nytimes.com/svc/search/v2/articlesearch.json?fq=web_url:(%22' +
	id + '%22)&api-key=' + nytimesKey;

	var details = {};
	var temp;

	axios.get(url)
	.then(function (response){
		var content = response.data.response.docs[0];

		if (content.headline && content.headline.main &&
			content.pub_date && content.abstract && content.web_url) {

			details['title'] = content.headline.main;
			details['image'] = nytimesDefaultImg;
			if (content.multimedia) {
				for (var i = 0; i < content.multimedia.length; i++) {
					var media = content.multimedia[i];
					if (media.url && media.width >= 2000) {
						details['image'] = 'https://www.nytimes.com/' + media.url;
						break;
					}
				}
			}
			details['date'] = content.pub_date.substr(0, 10);
			details['description'] = content.abstract;
			details['sharelink'] = content.web_url;
			details['com'] = "nytimes";
		} else {
			// ???
		}

	}).catch(function (error){
		console.log(error);
		if (error.response.data.fault) {
			details['error'] = error.response.data.fault.faultstring;
		} else if (error.response.data) {
			details['error'] = error.response.data;
		}
	}).then(function(){
		res.json(details);
	});

});

app.get('/search/nytimes', (req, res) => {
	var keyword = req.query.keyword;
	var url = 'https://api.nytimes.com/svc/search/v2/articlesearch.json?q=' +
	keyword + '&api-key=' + nytimesKey;

	var nytimesNews = [];
	axios.get(url)
	.then(function (response) {
		var results = response.data.response.docs;
		for (var result of results) {
			if (result.headline && result.headline.main && result.news_desk &&
				result.pub_date && result.web_url) {
				var news = {};
				news['title'] = result.headline.main;
				news['image'] = nytimesDefaultImg;
				if (result.multimedia) {
					for (var i = 0; i < result.multimedia.length; i++) {
						var media = result.multimedia[i];
						if (media.url && media.width >= 2000) {
							news['image'] = 'https://www.nytimes.com/' + media.url;
							break;
						}
					}
				}
				news['section'] = result.news_desk;
				news['date'] = result.pub_date.substr(0, 10);
				news['sharelink'] = result.web_url;
				news['id'] = result.web_url;
				news['com'] = "nytimes";
				nytimesNews.push(news);
			}
		}
		res.json(nytimesNews);
	}).catch(function (error) {
		console.log(error);
		if (error.response.data.fault) {
			res.json({'error': error.response.data.fault.faultstring});
		} else if (error.response.data) {
			res.json({'error': error.response.data});
		}
	});

});


// APIs to call
// Guardian for home tab:
// https://content.guardianapis.com/search?api-key=[KEY]&section=(sport|business|technology|politics)&show-blocks=all
// Guardian for section tabs:
// https://content.guardianapis.com/[section_name]?api-key=[KEY]&show-blocks=all
// Guardian for details:
// https://content.guardianapis.com/[article_id]?api-key=[KEY]&show-blocks=all
// Guardian for search:
// https://content.guardianapis.com/search?q=[QUERY_KEYWORD]&api-key=[KEY]&show-blocks=all

// NY times for home tab:
// https://api.nytimes.com/svc/topstories/v2/home.json?api-key=[KEY]
// NY times for section tabs:
// https://api.nytimes.com/svc/topstories/v2/[section_name].json?api-key=[KEY]
// NY times for details:
// https://api.nytimes.com/svc/search/v2/articlesearch.json?fq=web_url:(“[ARTICLE_WEB_URL]”)&api-key=[KEY]
// NY times for search:
// https://api.nytimes.com/svc/search/v2/articlesearch.json?q=[CITY]&apikey=[KEY]


app.listen(8081);
