var CHART_OFFSET_X = 150;
var CHART_WIDTH = 600;
var DATA_LABEL_OFFSET_X = 10;
var BAR_HEIGHT = 20;
var BAR_SPACING = 10;
var BAR_HEIGHT_TOTAL = BAR_HEIGHT + BAR_SPACING;

var BLUES   = ["#deebf7", "#c6dbef", "#9ecae1", "#6baed6", "#4292c6", "#2171b5", "#08519c"];
var GREENS  = ["#e5f5e0", "#c7e9c0", "#a1d99b", "#74c476", "#41ab5d", "#238b45", "#006d2c"];
var BLACKS  = ["#f0f0f0", "#d9d9d9", "#bdbdbd", "#969696", "#737373", "#525252", "#252525"];
var ORANGES = ["#fee6ce", "#fdd0a2", "#fdae6b", "#fd8d3c", "#f16913", "#d94801", "#a63603"];
var VIOLETS = ["#efedf5", "#dadaeb", "#bcbddc", "#9e9ac8", "#807dba", "#6a51a3", "#54278f"];
var REDS    = ["#fee0d2", "#fcbba1", "#fc9272", "#fb6a4a", "#ef3b2c", "#cb181d", "#a50f15"];
var NCOLORS = 7;
var COLORS = [BLUES, GREENS, ORANGES, VIOLETS, REDS, BLACKS];

var PALETTE = ["#edf8fb", "#ccece6", "#99d8c9", "#66c2a4", "#2ca25f", "#006d2c"].reverse();
//var PALETTE = ["#f1eef6", "#d4b9da", "#c994c7", "#df65b0", "#dd1c77", "#980043"].reverse();
//var PALETTE = ["#fee5d9", "#fcbba1", "#fc9272", "#fb6a4a", "#de2d26", "#a50f15"].reverse();
//var PALETTE = ["#f2f0f7", "#dadaeb", "#bcbddc", "#9e9ac8", "#756bb1", "#54278f"].reverse();
//var PALETTE = ["#ffffcc", "#c7e9b4", "#7fcdbb", "#41b6c4", "#2c7fb8", "#253494"].reverse();

function color_at(i, j) {
    return PALETTE[(i+j)%PALETTE.length];
    //return COLORS[i % COLORS.length][NCOLORS - 1 - j % NCOLORS];
}

function format_time(time) {
    return parseFloat(Math.round(time * 100) / 100).toFixed(2) + " µs/op";
}

function add_chart(name, tests, scale) {
    d3.select("body").append("h2").text(name);
    var svg = d3.select("body").append("svg");
    make_chart(svg, name, tests, scale);
}

function make_chart(svg, name, tests, scale) {
    var svgWidth = 1000;
    var svgHeight = _.keys(tests).length * BAR_HEIGHT_TOTAL + 50;
    svg.attr({
        width: svgWidth,
        height: svgHeight,
    });

    var nums = _.map(tests, function(val) { return val.elapsed / val.n; });
    var names = _.map(tests, function(val, name) { return name; });

    var dataScale;
    if (scale == "linear") {
        dataScale = d3.scale.linear().domain([0, d3.max(nums)]).range([0, CHART_WIDTH]);
    } else if (scale == "log") {
        dataScale = d3.scale.log().domain([1, d3.max(nums)]).range([0, CHART_WIDTH]);
    }

    svg.selectAll("rect")
        .data(nums)
        .enter()
            .append("rect")
            .attr({
                x: CHART_OFFSET_X,
                y: function(d, i) { return i * (BAR_HEIGHT + BAR_SPACING); },
                width: function(d) { return dataScale(d); },
                height: BAR_HEIGHT,
                fill: function(d, i) { return color_at(i, 0); },
            });

    svg.selectAll("text.label")
        .data(names)
        .enter()
            .append("text")
            .attr({
                class: "label",
                y: function(d, i) { return i * BAR_HEIGHT_TOTAL + BAR_HEIGHT_TOTAL/2; },
            })
            .text(function(d) { return d; });

    svg.selectAll("text.timing")
        .data(nums)
        .enter()
            .append("text")
            .attr({
                class: "timing",
                x: CHART_OFFSET_X + CHART_WIDTH + DATA_LABEL_OFFSET_X,
                y: function(d, i) { return i * 30 + 15; },
            })
            .text(function(d) { return format_time(d); });

    var xAxis = d3.svg.axis()
        .scale(dataScale)
        .ticks(5);

    var axisY = nums.length * 30;
    svg.append("g")
        .attr({transform: "translate("+CHART_OFFSET_X+", "+axisY+")"})
        .attr("class", "data-axis")
        .call(xAxis);
}

var data = JSON.parse($("#json-data").html());
var lookupScale = {
    linear: "linear",
    log10: "log",
};

function redrawCharts(scale) {
    $("h1").remove();
    $("h2").remove();
    $("svg").remove();
    _.each(data, function(dict, name) {
        $("<h1/>").text(name).appendTo($("body"));
        _.each(dict.tests, function(tests, name) {
            add_chart(name, tests, scale);
        });
    });
}

$("#scale-selector").click(function() {
    var scale = lookupScale[$(this).val()];
    redrawCharts(scale);
});

$(function() {
    redrawCharts("log");
});
