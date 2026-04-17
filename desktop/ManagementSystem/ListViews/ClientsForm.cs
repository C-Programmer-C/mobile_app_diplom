using ManagementSystem.DetailViews;
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
    public partial class ClientsForm: Form
    {
        public string ViewMode { get; set; } = "clients";
        private readonly JavaScriptSerializer _serializer = new JavaScriptSerializer();
        private readonly List<Dictionary<string, object>> _clients = new List<Dictionary<string, object>>();
        private FlowLayoutPanel _listPanel;
        private TextBox _search;
        private ComboBox _sortByCreated;

        public ClientsForm()
        {
            InitializeComponent();
            InitUi();
        }

		private async void ClientsForm_Load(object sender, EventArgs e)
		{
            ConfigureModeUi();
            await LoadClientsAsync();
		}

		private void ClientsForm_FormClosing(object sender, FormClosingEventArgs e)
		{
			this.Close();
		}

        private void InitUi()
        {
            ClientSize = new Size(800, 492);
            button1.Click += buttonCreate_Click;
            var buttonBack = new Button { Text = "Назад", Left = 12, Top = 63, Width = 90 };
            buttonBack.Click += (s, e) =>
            {
                Hide();
                new MenuForm().Show();
            };
            Controls.Add(buttonBack);

            _search = new TextBox { Left = 120, Top = 63, Width = 220 };
            _sortByCreated = new ComboBox { Left = 350, Top = 63, Width = 220, DropDownStyle = ComboBoxStyle.DropDownList };
            _sortByCreated.Items.AddRange(new object[] { "Дата: сначала новые", "Дата: сначала старые" });
            _sortByCreated.SelectedIndex = 0;
            var buttonApply = new Button { Left = 530, Top = 63, Width = 100, Text = "Применить" };
            buttonApply.Click += (s, e) => ApplyFilters();
            Controls.Add(_search);
            Controls.Add(_sortByCreated);
            Controls.Add(buttonApply);

            _listPanel = new FlowLayoutPanel
            {
                Left = 12,
                Top = 102,
                Width = 776,
                Height = 378,
                AutoScroll = true,
                FlowDirection = FlowDirection.TopDown,
                WrapContents = false,
                BackColor = SystemColors.ControlLight
            };
            Controls.Add(_listPanel);
            Load += ClientsForm_Load;
        }

        private async Task LoadClientsAsync()
        {
            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", UserSession.AccessToken);
                var endpoint = ViewMode == "staffs"
                    ? $"{ApiConfig.BaseUrl}/auth/users"
                    : $"{ApiConfig.BaseUrl}/auth/users?role=user";
                var response = await client.GetAsync(endpoint);
                if (!response.IsSuccessStatusCode)
                {
                    MessageBox.Show($"Ошибка загрузки пользователей ({(int)response.StatusCode})");
                    return;
                }
                var json = await response.Content.ReadAsStringAsync();
                var items = _serializer.DeserializeObject(json) as object[];
                _clients.Clear();
                if (items != null)
                {
                    foreach (var item in items)
                    {
                        var entry = item as Dictionary<string, object>;
                        if (entry == null) continue;
                        if (ViewMode == "staffs")
                        {
                            var role = Convert.ToString(entry.ContainsKey("role") ? entry["role"] : "") ?? "";
                            if (role == "admin" || role == "staff")
                            {
                                _clients.Add(entry);
                            }
                        }
                        else
                        {
                            _clients.Add(entry);
                        }
                    }
                }
                ApplyFilters();
            }
        }

        private void ApplyFilters()
        {
            var search = (_search.Text ?? string.Empty).Trim().ToLowerInvariant();
            var rows = _clients.Where(c =>
            {
                var name = Convert.ToString(c.ContainsKey("name") ? c["name"] : "") ?? "";
                var email = Convert.ToString(c.ContainsKey("email") ? c["email"] : "") ?? "";
                var phone = Convert.ToString(c.ContainsKey("phone") ? c["phone"] : "") ?? "";
                if (string.IsNullOrWhiteSpace(search)) return true;
                return name.ToLowerInvariant().Contains(search)
                    || email.ToLowerInvariant().Contains(search)
                    || phone.ToLowerInvariant().Contains(search);
            });

            var sortMode = Convert.ToString(_sortByCreated.SelectedItem) ?? "Дата: сначала новые";
            if (sortMode == "Дата: сначала старые")
            {
                rows = rows.OrderBy(GetCreatedAtOrMin);
            }
            else
            {
                rows = rows.OrderByDescending(GetCreatedAtOrMin);
            }

            var list = rows.ToList();

            _listPanel.Controls.Clear();
            if (list.Count == 0)
            {
                _listPanel.Controls.Add(new Label { Text = "Ничего не найдено", AutoSize = true });
                return;
            }

            foreach (var row in list)
            {
                _listPanel.Controls.Add(BuildClientCard(row));
            }
        }

        private void ConfigureModeUi()
        {
            if (ViewMode == "staffs")
            {
                label1.Text = "Сотрудники";
                button1.Text = "Создать сотрудника";
            }
            else
            {
                label1.Text = "Клиенты";
                button1.Text = "Создать пользователя";
            }
            button1.Visible = UserSession.UserRole == "admin";
        }

        private static DateTime GetCreatedAtOrMin(Dictionary<string, object> c)
        {
            var createdAt = Convert.ToString(c.ContainsKey("created_at") ? c["created_at"] : "") ?? "";
            if (DateTime.TryParse(createdAt, out var dt))
            {
                return dt;
            }
            return DateTime.MinValue;
        }

        private Panel BuildClientCard(Dictionary<string, object> c)
        {
            var idValue = c.ContainsKey("id") ? Convert.ToInt32(c["id"]) : 0;
            var card = new Panel
            {
                Width = 740,
                Height = 110,
                BackColor = Color.White,
                BorderStyle = BorderStyle.FixedSingle,
                Margin = new Padding(4),
                Tag = idValue,
            };

            var name = Convert.ToString(c.ContainsKey("name") ? c["name"] : "") ?? "-";
            var email = Convert.ToString(c.ContainsKey("email") ? c["email"] : "") ?? "-";
            var phone = Convert.ToString(c.ContainsKey("phone") ? c["phone"] : "") ?? "-";
            var role = Convert.ToString(c.ContainsKey("role") ? c["role"] : "") ?? "-";
            var id = Convert.ToString(c.ContainsKey("id") ? c["id"] : "") ?? "-";

            card.Click += Card_Click;

            var line1 = new Label { Left = 12, Top = 10, Width = 700, Height = 24, Font = new Font("Segoe UI", 10, FontStyle.Bold), Text = $"{name} (ID: {id})" };
            var line2 = new Label { Left = 12, Top = 40, Width = 700, Height = 20, Text = $"Логин: {email}" };
            var line3 = new Label { Left = 12, Top = 62, Width = 700, Height = 20, Text = $"Телефон: {phone}" };
            var line4 = new Label { Left = 12, Top = 84, Width = 700, Height = 20, Text = $"Роль: {role}" };
            line1.Click += Card_Click;
            line2.Click += Card_Click;
            line3.Click += Card_Click;
            line4.Click += Card_Click;

            card.Controls.Add(line1);
            card.Controls.Add(line2);
            card.Controls.Add(line3);
            card.Controls.Add(line4);
            return card;
        }

		private void Card_Click(object sender, EventArgs e)
		{
            Control control = sender as Control;
            while (control != null && !(control is Panel && control.Tag is int))
            {
                control = control.Parent;
            }
            if (control == null) return;

            var panel = (Panel)control;
            var userId = (int)panel.Tag;
            UserForm form = new UserForm();
            form.UserId = userId;
            form.ReturnViewMode = ViewMode;
            this.Hide();
            form.Show();
		}

        private void buttonCreate_Click(object sender, EventArgs e)
        {
            var form = new UserForm
            {
                IsCreateMode = true,
                ReturnViewMode = ViewMode,
                DefaultRole = ViewMode == "staffs" ? "staff" : "user",
            };
            Hide();
            form.Show();
        }
	}
}
