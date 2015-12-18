<%@ Page Language="C#" Debug="true" %>

<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="SharpCity" %>
<%@ Import Namespace="TeamCitySharp" %>
<%@ Import Namespace="TeamCitySharp.ActionTypes" %>
<%@ Import Namespace="TeamCitySharp.Connection" %>
<%@ Import Namespace="TeamCitySharp.DomainEntities" %>

<%@ OutputCache Duration="300" VaryByParam="projectid" %>

<script runat="server">

    private string DashboardUserName = "Dashboard";
    private string DashboardPassword = "P@ssw0rd";

    private string TeamCityUrl = "teamcity.racqgroup.local";
    private string TeamCityStatistics = "/app/rest/builds/BUILDNUMBER/statistics/";

    protected override void OnLoad(EventArgs e)
    {
        Response.Clear();
        Response.Cache.SetExpires(DateTime.Now.AddMinutes(5d));
        Response.Cache.SetCacheability(HttpCacheability.Public);
        Response.Cache.SetValidUntilExpires(true);
        Response.ContentType = "application/json; charset=utf-8";
        Response.AddHeader("Access-Control-Allow-Origin", "*");

        string projectid = Server.UrlDecode(Request.QueryString["projectid"]);
        if (string.IsNullOrEmpty(projectid))
        {
            Response.Write("{ \"Filter\" : \"Missing\" }");
            return;
        }

        var teamCity = new SharpCityClient(TeamCityUrl);
        teamCity.Connect(DashboardUserName, DashboardPassword);
        var projects = teamCity.Projects.All().Where(p => !String.IsNullOrEmpty(p.Description) && p.Description.IndexOf(projectid) > -1);

        var json = new StringBuilder();

        json.Append("{ \"Filter\" : \"" + projectid + "\", \"Projects\" : [");

        foreach (var project in projects)
        {
            var buildConfig = teamCity.BuildConfigs.ByProjectId(project.Id).Where(b => !String.IsNullOrEmpty(b.Name) && b.Name.ToUpper().Replace(" ", "").IndexOf("OCTOPUSDEPLOY") == -1).FirstOrDefault();

            if (buildConfig != null)
            {
                json.Append(" { \"Name\" : \"" + project.Name + "\", \"Config\" : \"" + buildConfig.Name + "\"");

                var build = teamCity.Builds.LastBuildByBuildConfigId(buildConfig.Id);
                if (build != null)
                {
                    json.Append(", \"Status\" : \"" + build.Status + "\", \"Number\" : \"" + build.Number + "\"");

                    var artifacts = teamCity.Artifacts.ByBuildNumber(build.Id);

                    json.Append(", \"Artefacts\" : [ ");

                    bool artifactsappended = false;
                    foreach (var artifact in artifacts)
                    {
                        if (artifact == null) continue;
                        json.Append(" { \"File\" : { \"Name\" : \"" + artifact.ToString() + "\", \"ContentHref\" : \"http://" + TeamCityUrl + artifact.Content.Href + "\" } },");
                        artifactsappended = true;
                    }

                    if (artifactsappended) json.Remove(json.ToString().Length - 1, 1);

                    json.Append(" ], ");

                    var stats = teamCity.Statistics.ByBuildNumber(build.Id);

                    json.Append(" \"Statistics\" : {");

                    bool statsappended = false;
                    foreach (var stat in stats)
                    {
                        if (stat == null) continue;
                        json.Append(" \"" + stat.Name + "\" : \"" + stat.Value + "\",");
                        statsappended = true;
                    }
                    if (statsappended) json.Remove(json.ToString().Length - 1, 1);

                    json.Append("}, ");

                    var specFlow = teamCity.SpecFlowTests.GetResults(build.Id);

                    json.Append(" \"SpecFlow\" : { ");

                    if (specFlow != null)
                    {
                        foreach (dynamic item in specFlow.Items.Where(i => i.GetType().ToString() == "TestRunTypeResultSummary"))
                        {
                            json.Append(" \"Outcome\" : \"" + item.outcome + "\" ");
                            if (item.Items != null)
                            {
                                json.Append(",");

                                bool outcomesappended = false;

                                foreach (dynamic subitem in item.Items)
                                {
                                    if (subitem.GetType().ToString() == "CountersType")
                                    {
                                        json.Append(" \"Executed\" : " + subitem.executed);
                                        json.Append(", ");
                                        json.Append(" \"Error\" : " + subitem.error);
                                        json.Append(", ");
                                        json.Append(" \"Inconclusive\" : " + subitem.inconclusive);
                                        json.Append(", ");
                                        json.Append(" \"PassRate\" : " + (((subitem.passed - subitem.inconclusive) / subitem.executed) * 100));
                                        json.Append(",");
                                        outcomesappended = true;
                                    }
                                }
                                if (outcomesappended) json.Remove(json.ToString().Length - 1, 1);
                            }
                        }
                    }

                    json.Append("}");
                }

                json.Append("},");
            }
        }

        json.Remove(json.ToString().Length - 1, 1);
        json.Append("]}");

        Response.Write(json.ToString());
    }
	
</script>