<%@ Page Language="C#" Debug="true" %>

<html>
<head>
    <title>Team City Builds</title>
    <script src="http://code.jquery.com/jquery-2.1.3.min.js"></script>
    <script runat="server">

        protected void Page_Load(object sender, EventArgs e)
        {

        }

    </script>
    <script>

        var teamcityLatestBuildRestAPI = "/Jira_Dashboard_Extensions/teamcityproxy.aspx" + location.search;

    </script>
    <style>
        body {
            background-color: white;
            color: black;
            font-family: 'Courier New', Courier, 'Lucida Sans Typewriter', 'Lucida Typewriter', monospace;
        }

        .WallBoard {
            background-color: black;
            color: white;
        }

        #Filter {
            font-size: 22pt;
        }

        .Build {
            width: 160px;
            height: 80px;
            margin: 5px;
            float: left;
            font-size: 12pt;
			-webkit-column-break-inside: avoid;
			-moz-column-break-inside: avoid;
			column-break-inside: avoid;		
        }

        .Build_Name {
            word-wrap: break-word;
            position: relative;
            top: 0px;
            left: 0px;
            width: 100%;
            height: 70%;
            margin: 2px;
            clear: both;
            display: block;
            z-index: 1;
            border: 0px solid lime;
        }

        .Build_Number {
            height: 30%;
            width: 100%;
            left: 0px;
            top: 0px;
            text-align: right;
            vertical-align: bottom;
            border: 0px solid black;
            margin: 2px;
            display: block;
            clear: both;
            font-weight: bold;
            float: right;
            position: relative;
        }

        .Build_SpecflowOutcome {
            height: 30%;
            width: 100%;
            display: inline;
            clear: both;
            float: left;
            top: -24px;
            margin: 2px;
            position: relative;
            border: 0px solid cyan;
            font-size: 8pt;
        }

        .FAILED .Warning.Build_SpecflowOutcome {
            top: -55px;
        }

        .SUCCESS {
            background-color: green;
        }

        .FAILURE {
            background-color: red;
            font-size: 24pt;
            height: 160px;
			width: 320px;
            margin: 10px;
        }

		.Build_SpecflowOutcome.Pass {
            color: White;
        }
		
        .Build_SpecflowOutcome.Warning, .Build_SpecflowOutcome.Inconclusive {
            color: orange;
        }

        .Build_SpecflowOutcome.Error, .Build_SpecflowOutcome.Missing {
            color: red;
        }
		
		#wrapper {
			width: 100%;
		}

		#Projects {
			-webkit-column-count: auto;
			-moz-column-count: auto;
			column-count: auto;
			
			-webkit-column-gap: 5px;
			-moz-column-gap: 5px;
			column-gap: 5px;
			
			-webkit-column-fill: auto;
			-moz-column-fill: auto;		
			column-fill: auto;
		}
	
    </style>
	
</head>
<body>

	<audio preload="auto" id="failureSound">
		<source src="failure.wav" type="audio/wav">
	</audio>

    <div id="Filter">Team City Builds for </div>

	<div id="Loading">
		Loading...
	</div>

	<div id="wrapper">
		<div id="Projects">
		</div>
	</div>
    
    <script>
	
		$(document).ajaxStart(function () {
            $("#Loading").show();
        });

        $(document).ajaxStop(function () {
            if (0 === $.active) {
                $("#Loading").hide();
				if (document.referrer.indexOf("/plugins/servlet/gadgets/") > 0) {
					$("html, body").animate({ scrollTop: $(document).height() }, 3000);
				}
            }
        });
	
        $(document).ready(function () {

            $("#Filter").hide();

            if (document.referrer.indexOf("/plugins/servlet/gadgets/") > 0) {
                $("body").addClass("Wallboard");
            }

            $.ajax({
                url: teamcityLatestBuildRestAPI,
                type: "GET",
                complete: function (xhr, status) {
                    if (status === 'error' || !xhr.responseText) {
                        $("#Jira").append(status);
                    } else {
                        var data = jQuery.parseJSON(xhr.responseText);
                        $("#Filter").append(data.Filter).show();
                        $.each(data.Projects, function (i, v) {
							if (v.Config && v.Config != "CI")
							{
								return;
							}
							if (!v.Number) 
							{
								return;
							}
                            var build = "";
                            build += "<div class='Build " + v.Status + "'>";
                            build += "<div class='Build_Name'>";
                            build += v.Name;
                            build += "</div>";
                            build += "<div class='Build_Number'>";
                            build += v.Number;
                            build += "</div>";
							var outcome = "Missing";
                            if (v.SpecFlow && v.SpecFlow.Outcome) {
								outcome = v.SpecFlow.Outcome;
								if (v.SpecFlow.PassRate && v.SpecFlow.PassRate == 100) 
								{
									outcome = "Pass";
								}
                            }							
							build += "<div class='Build_SpecflowOutcome " + outcome + "'>";
							build += outcome == "Missing" ? "*" : outcome;
                            build += "</div>";
							
                            build += "</div>";
                            $("#Projects").append(build);
							
							if (v.Status == "FAILURE") 
							{
								$('failureSound').trigger('play');
							}
                        });
                    }
                }
            });
			
			if (document.referrer.indexOf("/plugins/servlet/gadgets/") > 0) {
				$("html, body").animate({ scrollTop: $(document).height() }, "slow");
			}
        });

    </script>
</body>
</html>