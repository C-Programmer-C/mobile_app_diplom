using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Windows.Forms;

namespace ManagementSystem
{
    public partial class AuthForm: Form
    {
        private string _authorizedUserName = string.Empty;

        public AuthForm()
        {
            InitializeComponent();
        }

		private void button1_Click(object sender, EventArgs e)
		{
            if (textBox1.Text == String.Empty || textBox2.Text == String.Empty)
            {
                return;
            }

            var role = GetRole();

            if (role == String.Empty)
            {
				MessageBox.Show("Пользователь не найден!");
				return;
			}

            if (role == "invalid_login_format")
            {
                MessageBox.Show("Логин должен быть в формате email");
                return;
            }

            if (role == "role_not_provided")
            {
                MessageBox.Show("Роль не указана!");
                return;
            }

            MenuForm menuForm = new MenuForm();
            menuForm.UserRole = role;
            menuForm.UserName = _authorizedUserName;
            

			menuForm.Show();
            this.Hide();
		}

        private string GetRole()
        {
            using (var client = new HttpClient())
            {
                client.BaseAddress = new Uri("https://cheekily-coherent-newfoundland.cloudpub.ru");
                var serializer = new JavaScriptSerializer();
                var login = textBox1.Text.Trim();
                var password = textBox2.Text;

                if (string.IsNullOrWhiteSpace(login) || string.IsNullOrWhiteSpace(password))
                {
                    return string.Empty;
                }

                if (!login.Contains("@"))
                {
                    return "invalid_login_format";
                }

                var loginPayload = serializer.Serialize(new { email = login, password = password });

                var loginResponse = client
                    .PostAsync(
                        "/auth/login",
                        new StringContent(loginPayload, Encoding.UTF8, "application/json")
                    )
                    .Result;

                if ((int)loginResponse.StatusCode == 422)
                {
                    return "invalid_login_format";
                }

                if (!loginResponse.IsSuccessStatusCode)
                {
                    return string.Empty;
                }

                var loginJson = loginResponse.Content.ReadAsStringAsync().Result;
                var loginData = serializer.DeserializeObject(loginJson) as Dictionary<string, object>;

                if (loginData == null || !loginData.ContainsKey("access_token"))
                {
                    return string.Empty;
                }

                var accessToken = Convert.ToString(loginData["access_token"]);
                var userName = loginData.ContainsKey("name")
                    ? Convert.ToString(loginData["name"])
                    : string.Empty;
                _authorizedUserName = userName ?? string.Empty;
                UserSession.AccessToken = accessToken ?? string.Empty;
                if (string.IsNullOrWhiteSpace(accessToken))
                {
                    return string.Empty;
                }

                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
                    "Bearer",
                    accessToken
                );

                var meResponse = client.GetAsync("/auth/me").Result;
                if (!meResponse.IsSuccessStatusCode)
                {
                    return string.Empty;
                }

                var meJson = meResponse.Content.ReadAsStringAsync().Result;
                var meData = serializer.DeserializeObject(meJson) as Dictionary<string, object>;
                if (meData == null)
                {
                    return string.Empty;
                }
                
                if (meData.ContainsKey("role"))
                {
                    if (string.IsNullOrWhiteSpace(userName) && meData.ContainsKey("name"))
                    {
                        userName = Convert.ToString(meData["name"]);
                    }
                    _authorizedUserName = userName ?? string.Empty;
                    UserSession.UserName = _authorizedUserName;
                    UserSession.UserRole = Convert.ToString(meData["role"]) ?? string.Empty;
                    return Convert.ToString(meData["role"]) ?? string.Empty;
                }
                
                return "role_not_provided";
            }
        }

		private void AuthForm_FormClosed(object sender, FormClosedEventArgs e)
		{
            this.Close();
		}
	}
}
