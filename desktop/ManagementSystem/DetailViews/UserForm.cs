using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.RegularExpressions;
using System.Text;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Windows.Forms;

namespace ManagementSystem.DetailViews
{
    public partial class UserForm: Form
    {
        public int UserId { get; set; }
        public bool IsCreateMode { get; set; }
        public string DefaultRole { get; set; } = "user";
        public string ReturnViewMode { get; set; } = "clients";
        private readonly JavaScriptSerializer _serializer = new JavaScriptSerializer();

        public UserForm()
        {
            InitializeComponent();
            EnsureCreateControls();
        }

		private async void UserForm_Load(object sender, EventArgs e)
		{
            comboBox1.Items.Clear();
            comboBox1.Items.AddRange(new object[] { "user", "staff", "admin" });
            comboBox1.DropDownStyle = ComboBoxStyle.DropDownList;
            button1.Click += button1_Click;
            if (IsCreateMode)
            {
                this.Size = new Size(719, 520);
                SetupCreateModeUi();
                return;
            }
            await LoadUserAsync();
		}

		private void UserForm_FormClosing(object sender, FormClosingEventArgs e)
		{
            this.Close();
		}

        private async Task LoadUserAsync()
        {
            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", UserSession.AccessToken);
                var response = await client.GetAsync($"{ApiConfig.BaseUrl}/auth/users/{UserId}/details");
                if (!response.IsSuccessStatusCode)
                {
                    MessageBox.Show($"Ошибка загрузки пользователя ({(int)response.StatusCode})");
                    return;
                }

                var json = await response.Content.ReadAsStringAsync();
                var user = _serializer.DeserializeObject(json) as Dictionary<string, object>;
                if (user == null) return;

                textBox1.Text = Convert.ToString(user.ContainsKey("id") ? user["id"] : "") ?? "";
                textBox2.Text = Convert.ToString(user.ContainsKey("email") ? user["email"] : "") ?? "";
                textBox3.Text = Convert.ToString(user.ContainsKey("phone") ? user["phone"] : "") ?? "";
                textBox4.Text = Convert.ToString(user.ContainsKey("name") ? user["name"] : "") ?? "";
                var userRole = Convert.ToString(user.ContainsKey("role") ? user["role"] : "") ?? "user";
                comboBox1.SelectedItem = comboBox1.Items.Contains(userRole) ? userRole : "user";

                var createdAt = Convert.ToString(user.ContainsKey("created_at") ? user["created_at"] : "") ?? "";
                if (DateTime.TryParse(createdAt, out var dt))
                {
                    dateTimePicker1.Value = dt;
                }

                label1.Text = userRole == "user" ? "Информация о клиенте" : "Информация о сотруднике";

                var canEdit = UserSession.UserRole == "admin";
                textBox2.Enabled = canEdit;
                textBox3.Enabled = canEdit;
                textBox4.Enabled = canEdit;
                comboBox1.Enabled = canEdit;
                button1.Enabled = canEdit;
                button1.Visible = true;

                var reviews = user.ContainsKey("reviews") ? user["reviews"] as object[] : null;
                var orders = user.ContainsKey("orders") ? user["orders"] as object[] : null;
                RenderComments(reviews);
                RenderOrders(orders);
            }
        }

        private async void button1_Click(object sender, EventArgs e)
        {
            if (IsCreateMode)
            {
                await CreateUserAsync();
                return;
            }

            if (UserSession.UserRole != "admin")
            {
                MessageBox.Show("Редактирование доступно только администратору");
                return;
            }

            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", UserSession.AccessToken);
                var payload = _serializer.Serialize(
                    new
                    {
                        email = textBox2.Text.Trim(),
                        phone = textBox3.Text.Trim(),
                        name = textBox4.Text.Trim(),
                        role = Convert.ToString(comboBox1.SelectedItem) ?? "user",
                    }
                );
                var request = new HttpRequestMessage(
                    new HttpMethod("PATCH"),
                    $"{ApiConfig.BaseUrl}/auth/users/{UserId}"
                )
                {
                    Content = new StringContent(payload, Encoding.UTF8, "application/json"),
                };
                var response = await client.SendAsync(request);
                if (!response.IsSuccessStatusCode)
                {
                    MessageBox.Show(await BuildServerErrorMessageAsync("Ошибка изменения пользователя", response));
                    return;
                }
                MessageBox.Show("Изменения сохранены");
                await LoadUserAsync();
                ClientsForm clientsForm = new ClientsForm
                {
                    ViewMode = ReturnViewMode,
                };
                clientsForm.Show();
                this.Hide();
            }
        }

        private void SetupCreateModeUi()
        {
            label1.Text = "Создание пользователя";
            textBox1.Text = "";
            textBox1.Enabled = false;
            textBox2.Text = "";
            textBox2.Enabled = true;
            textBox3.Text = "";
            textBox3.Enabled = true;
            textBox4.Text = "";
            textBox4.Enabled = true;
            comboBox1.Enabled = true;
            comboBox1.SelectedItem = comboBox1.Items.Contains(DefaultRole) ? DefaultRole : "user";
            dateTimePicker1.Value = DateTime.Now;
            dateTimePicker1.Enabled = false;
            button1.Text = "Создать";
            button1.Enabled = UserSession.UserRole == "admin";
            label8.Visible = true;
            textBoxPassword.Visible = true;
            textBoxPassword.Text = "";
            labelComments.Visible = false;
            labelOrders.Visible = false;
            flowLayoutPanelShowComments.Visible = false;
            flowLayoutPanelShowOrders.Visible = false;
        }

        private async Task CreateUserAsync()
        {
            if (UserSession.UserRole != "admin")
            {
                MessageBox.Show("Создание доступно только администратору");
                return;
            }

            var email = textBox2.Text.Trim();
            var password = textBoxPassword.Text;
            var name = textBox4.Text.Trim();
            var phone = textBox3.Text.Trim();
            var role = Convert.ToString(comboBox1.SelectedItem) ?? "user";
            if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(name) || string.IsNullOrWhiteSpace(password))
            {
                MessageBox.Show("Заполни обязательные поля (email, пароль, имя)");
                return;
            }
            if (!IsValidEmail(email))
            {
                MessageBox.Show("Некорректный email");
                return;
            }
            if (!string.IsNullOrWhiteSpace(phone) && !IsValidPhone(phone))
            {
                MessageBox.Show("Некорректный телефон. Пример: +79001234567");
                return;
            }
            if (password.Length < 6)
            {
                MessageBox.Show("Пароль должен быть не короче 6 символов");
                return;
            }

            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", UserSession.AccessToken);
                var payload = _serializer.Serialize(
                    new
                    {
                        email = email,
                        password = password,
                        name = name,
                        phone = phone,
                        role = role,
                    }
                );
                var response = await client.PostAsync(
                    $"{ApiConfig.BaseUrl}/auth/users",
                    new StringContent(payload, Encoding.UTF8, "application/json")
                );
                if (!response.IsSuccessStatusCode)
                {
                    MessageBox.Show(await BuildServerErrorMessageAsync("Ошибка создания пользователя", response));
                    return;
                }
            }
            MessageBox.Show("Пользователь создан");
            var clientsForm = new ClientsForm { ViewMode = ReturnViewMode };
            clientsForm.Show();
            Hide();
        }

        private void EnsureCreateControls()
        {
            label8 = new Label
            {
                Name = "label8",
                Text = "Пароль",
                Font = new Font("Times New Roman", 15.75F, FontStyle.Regular, GraphicsUnit.Point, 204),
                Left = 102,
                Top = 364,
                Width = 90,
                Visible = false,
            };
            textBoxPassword = new TextBox
            {
                Name = "textBoxPassword",
                Font = new Font("Times New Roman", 15.75F),
                Left = 201,
                Top = 361,
                Width = 348,
                UseSystemPasswordChar = true,
                Visible = false,
            };
            Controls.Add(label8);
            Controls.Add(textBoxPassword);
        }

        private static bool IsValidEmail(string email)
        {
            if (string.IsNullOrWhiteSpace(email)) return false;
            return Regex.IsMatch(email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$");
        }

        private static bool IsValidPhone(string phone)
        {
            if (string.IsNullOrWhiteSpace(phone)) return true;
            return Regex.IsMatch(phone, @"^\+?\d[\d\-\s\(\)]{5,19}$");
        }

        private async Task<string> BuildServerErrorMessageAsync(string prefix, HttpResponseMessage response)
        {
            try
            {
                var body = await response.Content.ReadAsStringAsync();
                if (string.IsNullOrWhiteSpace(body))
                {
                    return $"{prefix} ({(int)response.StatusCode})";
                }
                var payload = _serializer.DeserializeObject(body) as Dictionary<string, object>;
                if (payload != null && payload.ContainsKey("detail"))
                {
                    var detail = payload["detail"];
                    if (detail is object[] arr)
                    {
                        var joined = string.Join("; ", arr.Select(x => Convert.ToString(x)));
                        return $"{prefix}: {joined}";
                    }
                    return $"{prefix}: {Convert.ToString(detail)}";
                }
                return $"{prefix}: {body}";
            }
            catch
            {
                return $"{prefix} ({(int)response.StatusCode})";
            }
        }

        private void RenderComments(object[] reviews)
        {
            flowLayoutPanelShowComments.Controls.Clear();
            flowLayoutPanelShowComments.FlowDirection = FlowDirection.TopDown;
            flowLayoutPanelShowComments.WrapContents = false;
            flowLayoutPanelShowComments.AutoScroll = true;
            flowLayoutPanelShowComments.Visible = true;
            labelComments.Visible = true;

            if (reviews == null || reviews.Length == 0)
            {
                flowLayoutPanelShowComments.Controls.Add(new Label { AutoSize = true, Text = "Комментариев нет" });
                return;
            }

            foreach (var item in reviews)
            {
                var r = item as Dictionary<string, object>;
                if (r == null) continue;
                var panel = new Panel { Width = 660, Height = 62, BorderStyle = BorderStyle.FixedSingle, Margin = new Padding(4), BackColor = Color.White };
                var productName = Convert.ToString(r.ContainsKey("product_name") ? r["product_name"] : "") ?? "-";
                var rating = Convert.ToString(r.ContainsKey("rating") ? r["rating"] : "") ?? "-";
                var comment = Convert.ToString(r.ContainsKey("comment") ? r["comment"] : "") ?? "";
                panel.Controls.Add(new Label { Left = 8, Top = 8, Width = 640, Height = 18, Font = new Font("Segoe UI", 9, FontStyle.Bold), Text = $"{productName} | Оценка: {rating}" });
                panel.Controls.Add(new Label { Left = 8, Top = 30, Width = 640, Height = 20, Text = string.IsNullOrWhiteSpace(comment) ? "Без комментария" : comment });
                flowLayoutPanelShowComments.Controls.Add(panel);
            }
        }

        private void RenderOrders(object[] orders)
        {
            flowLayoutPanelShowOrders.Controls.Clear();
            flowLayoutPanelShowOrders.FlowDirection = FlowDirection.TopDown;
            flowLayoutPanelShowOrders.WrapContents = false;
            flowLayoutPanelShowOrders.AutoScroll = true;
            flowLayoutPanelShowOrders.Visible = true;
            labelOrders.Visible = true;

            if (orders == null || orders.Length == 0)
            {
                flowLayoutPanelShowOrders.Controls.Add(new Label { AutoSize = true, Text = "Заказов нет" });
                return;
            }

            foreach (var item in orders)
            {
                var o = item as Dictionary<string, object>;
                if (o == null) continue;
                var panel = new Panel { Width = 660, Height = 62, BorderStyle = BorderStyle.FixedSingle, Margin = new Padding(4), BackColor = Color.White };
                var id = Convert.ToString(o.ContainsKey("id") ? o["id"] : "") ?? "-";
                var status = TranslateStatus(Convert.ToString(o.ContainsKey("status") ? o["status"] : "") ?? "-");
                var total = Convert.ToString(o.ContainsKey("total_amount") ? o["total_amount"] : "") ?? "-";
                var payment = TranslatePaymentStatus(Convert.ToString(o.ContainsKey("payment_status") ? o["payment_status"] : "") ?? "-");
                panel.Controls.Add(new Label { Left = 8, Top = 8, Width = 640, Height = 18, Font = new Font("Segoe UI", 9, FontStyle.Bold), Text = $"Заказ #{id} | {status}" });
                panel.Controls.Add(new Label { Left = 8, Top = 30, Width = 640, Height = 20, Text = $"Сумма: {total} | Оплата: {payment}" });
                flowLayoutPanelShowOrders.Controls.Add(panel);
            }
        }

        private static string TranslateStatus(string status)
        {
            switch ((status ?? string.Empty).Trim().ToLowerInvariant())
            {
                case "pending":
                    return "Ожидает";
                case "confirmed":
                    return "Подтвержден";
                case "shipped":
                    return "В пути";
                case "delivered":
                    return "Доставлен";
                case "cancelled":
                    return "Отменен";
                default:
                    return string.IsNullOrWhiteSpace(status) ? "-" : status;
            }
        }

        private static string TranslatePaymentStatus(string status)
        {
            switch ((status ?? string.Empty).Trim().ToLowerInvariant())
            {
                case "paid":
                    return "Оплачен";
                case "pending":
                    return "Ожидает оплаты";
                case "failed":
                    return "Ошибка оплаты";
                case "refunded":
                    return "Возврат";
                default:
                    return string.IsNullOrWhiteSpace(status) ? "-" : status;
            }
        }

		private void button2_Click(object sender, EventArgs e)
		{
            this.Hide();
            ClientsForm form = new ClientsForm
            {
                ViewMode = ReturnViewMode,
            };
            form.Show();
		}

		private void button1_Click_1(object sender, EventArgs e)
		{

		}
	}
}
