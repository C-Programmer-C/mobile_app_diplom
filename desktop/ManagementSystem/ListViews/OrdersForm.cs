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
    public partial class OrdersForm: Form
    {
        private readonly JavaScriptSerializer _serializer = new JavaScriptSerializer();
        private readonly List<Dictionary<string, object>> _orders = new List<Dictionary<string, object>>();
        private FlowLayoutPanel _listPanel;
        private TextBox _search;
        private ComboBox _statusFilter;

        public OrdersForm()
        {
            InitializeComponent();
            InitUi();
        }

		private async void OrdersForm_Load(object sender, EventArgs e)
		{
            await LoadOrdersAsync();
		}

		private void OrdersForm_FormClosing(object sender, FormClosingEventArgs e)
		{
			this.Close();
		}

        private void InitUi()
        {
            ClientSize = new Size(800, 492);
            var buttonBack = new Button { Text = "Назад", Left = 12, Top = 63, Width = 90 };
            buttonBack.Click += (s, e) =>
            {
                Hide();
                new MenuForm().Show();
            };
            Controls.Add(buttonBack);

            _search = new TextBox { Left = 120, Top = 63, Width = 240 };
            _statusFilter = new ComboBox { Left = 370, Top = 63, Width = 180, DropDownStyle = ComboBoxStyle.DropDownList };
            _statusFilter.Items.AddRange(new object[] { "Все", "Ожидает", "Подтвержден", "В пути", "Доставлен", "Отменен" });
            _statusFilter.SelectedIndex = 0;
            var buttonApply = new Button { Left = 560, Top = 63, Width = 100, Text = "Применить" };
            buttonApply.Click += (s, e) => ApplyFilters();
            Controls.Add(_search);
            Controls.Add(_statusFilter);
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
            Load += OrdersForm_Load;
        }

        private async Task LoadOrdersAsync()
        {
            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", UserSession.AccessToken);
                var endpoint = UserSession.UserRole == "user" ? "/orders/me" : "/orders/all";
                var response = await client.GetAsync($"{ApiConfig.BaseUrl}{endpoint}");
                if (!response.IsSuccessStatusCode)
                {
                    MessageBox.Show($"Ошибка загрузки заказов ({(int)response.StatusCode})");
                    return;
                }
                var json = await response.Content.ReadAsStringAsync();
                var items = _serializer.DeserializeObject(json) as object[];
                _orders.Clear();
                if (items != null)
                {
                    foreach (var item in items)
                    {
                        var entry = item as Dictionary<string, object>;
                        if (entry != null) _orders.Add(entry);
                    }
                }
                ApplyFilters();
            }
        }

        private void ApplyFilters()
        {
            var search = (_search.Text ?? string.Empty).Trim().ToLowerInvariant();
            var status = Convert.ToString(_statusFilter.SelectedItem) ?? "Все";
            var rows = _orders.Where(o =>
            {
                var currentStatus = Convert.ToString(o.ContainsKey("status") ? o["status"] : "") ?? "";
                var customerName = Convert.ToString(o.ContainsKey("customer_name") ? o["customer_name"] : UserSession.UserName) ?? "";
                var orderId = Convert.ToString(o.ContainsKey("id") ? o["id"] : "") ?? "";
                var statusRu = TranslateStatus(currentStatus);
                if (status != "Все" && !statusRu.Equals(status, StringComparison.OrdinalIgnoreCase)) return false;
                if (string.IsNullOrWhiteSpace(search)) return true;
                return customerName.ToLowerInvariant().Contains(search) || orderId.Contains(search);
            }).ToList();

            _listPanel.Controls.Clear();
            if (rows.Count == 0)
            {
                _listPanel.Controls.Add(new Label { Text = "Ничего не найдено", AutoSize = true });
                return;
            }

            foreach (var row in rows)
            {
                _listPanel.Controls.Add(BuildOrderCard(row));
            }
        }

        private Panel BuildOrderCard(Dictionary<string, object> o)
        {
            var card = new Panel
            {
                Width = 740,
                Height = 135,
                BackColor = Color.White,
                BorderStyle = BorderStyle.FixedSingle,
                Margin = new Padding(4),
                Tag = o.ContainsKey("id") ? Convert.ToInt32(o["id"]) : 0,
            };

			card.Click += Card_Click;

            var id = Convert.ToString(o.ContainsKey("id") ? o["id"] : "") ?? "-";
            var userId = Convert.ToString(o.ContainsKey("user_id") ? o["user_id"] : "") ?? "-";
            var customer = Convert.ToString(o.ContainsKey("customer_name") ? o["customer_name"] : UserSession.UserName) ?? "-";
            var status = TranslateStatus(Convert.ToString(o.ContainsKey("status") ? o["status"] : "") ?? "-");
            var delivery = Convert.ToString(o.ContainsKey("delivery_type") ? o["delivery_type"] : "") ?? "-";
            var amount = Convert.ToString(o.ContainsKey("total_amount") ? o["total_amount"] : "") ?? "-";
            var payment = TranslatePaymentStatus(Convert.ToString(o.ContainsKey("payment_status") ? o["payment_status"] : "") ?? "-");
            var date = Convert.ToString(o.ContainsKey("created_at") ? o["created_at"] : "") ?? "-";
            var phone = Convert.ToString(o.ContainsKey("phone") ? o["phone"] : "") ?? "-";

            card.Click += Card_Click;
            var line1 = new Label { Left = 12, Top = 10, Width = 700, Height = 24, Font = new Font("Segoe UI", 10, FontStyle.Bold), Text = $"Заказ #{id} | User ID: {userId} | {customer}" };
            var line2 = new Label { Left = 12, Top = 38, Width = 700, Height = 20, Text = $"Статус: {status} | Доставка: {delivery}" };
            var line3 = new Label { Left = 12, Top = 60, Width = 700, Height = 20, Text = $"Сумма: {amount} | Оплата: {payment}" };
            var line4 = new Label { Left = 12, Top = 82, Width = 700, Height = 20, Text = $"Телефон: {phone}" };
            var line5 = new Label { Left = 12, Top = 104, Width = 700, Height = 20, Text = $"Дата: {date}" };
            line1.Click += Card_Click;
            line2.Click += Card_Click;
            line3.Click += Card_Click;
            line4.Click += Card_Click;
            line5.Click += Card_Click;
            card.Controls.Add(line1);
            card.Controls.Add(line2);
            card.Controls.Add(line3);
            card.Controls.Add(line4);
            card.Controls.Add(line5);
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
            var order = new OrderForm
            {
                OrderId = (int)panel.Tag,
            };
            Hide();
            order.Show();
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
			MenuForm menu = new MenuForm();
			menu.Show();
		}
	}
}
