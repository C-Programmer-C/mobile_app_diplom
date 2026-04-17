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

namespace ManagementSystem.DetailViews
{
    public partial class OrderForm: Form
    {
        public int OrderId { get; set; }
        private readonly JavaScriptSerializer _serializer = new JavaScriptSerializer();
        private readonly Dictionary<string, int> _deliveryTypeMap = new Dictionary<string, int>();
        private readonly Dictionary<string, int> _statusMap = new Dictionary<string, int>();
        private readonly Dictionary<string, int> _cityMap = new Dictionary<string, int>();
        private readonly Dictionary<string, int> _pickupMap = new Dictionary<string, int>();
        private Button _buttonBack;
        private Button _buttonChange;
        private Label _labelMeta;
        private Label _labelDates;
        private Dictionary<Control, int> _deliveryStackOrigTops;
        private bool _programmaticOrderLoad;
        private bool _forceNextStatusesLoad = true;
        private string _statusesCacheSignature;

        public OrderForm()
        {
            InitializeComponent();
            comboBox3.SelectedIndexChanged += ComboBox3_CitySelectedIndexChanged;
        }

        private async void ComboBox3_CitySelectedIndexChanged(object sender, EventArgs e)
        {
            if (_programmaticOrderLoad) return;
            await LoadPickupPointsAsync();
        }

		private void OrderForm_FormClosing(object sender, FormClosingEventArgs e)
		{
            this.Close();
		}

		private async void comboBox1_SelectedIndexChanged(object sender, EventArgs e)
		{
            ApplyDeliveryVisibility();
            if (_programmaticOrderLoad) return;
            if (!_deliveryTypeMap.TryGetValue(Convert.ToString(comboBox1.SelectedItem) ?? "", out var dtId))
                return;
            _forceNextStatusesLoad = true;
            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", UserSession.AccessToken);
                await LoadStatusesAsync(client, dtId);
            }
		}

		private async void OrderForm_Load(object sender, EventArgs e)
		{
            EnsureRuntimeButtons();
            comboBox1.DropDownStyle = ComboBoxStyle.DropDownList;
            comboBox2.DropDownStyle = ComboBoxStyle.DropDownList;
            comboBox3.DropDownStyle = ComboBoxStyle.DropDownList;
            comboBox4.DropDownStyle = ComboBoxStyle.DropDownList;
            labelComments.Visible = true;
            label6.Text = "Сумма";
            textBox5.Enabled = false;
            numericUpDown1.Enabled = false;
            checkBoxPaid.Enabled = UserSession.UserRole == "admin" || UserSession.UserRole == "staff";
            flowLayoutProducts.FlowDirection = FlowDirection.TopDown;
            await LoadMetaAsync();
            await LoadOrderAsync();
		}

        private void EnsureRuntimeButtons()
        {
            if (_buttonBack != null) return;
            _buttonBack = new Button
            {
                Name = "buttonBack",
                Text = "Назад",
                Font = new Font("Times New Roman", 14.25F),
                Left = 12,
                Top = 12,
                Width = 116,
                Height = 46,
            };
            _buttonBack.Click += (s, e) =>
            {
                Hide();
                new OrdersForm().Show();
            };
            Controls.Add(_buttonBack);

            _buttonChange = new Button
            {
                Name = "buttonChange",
                Text = "Изменить",
                Font = new Font("Times New Roman", 14.25F),
                Left = 430,
                Top = 627,
                Width = 180,
                Height = 46,
            };
            _buttonChange.Click += buttonChange_Click;
            Controls.Add(_buttonChange);

            _labelMeta = new Label
            {
                Name = "labelMeta",
                Left = 656,
                Top = 307,
                Width = 494,
                Height = 88,
                Font = new Font("Times New Roman", 14, FontStyle.Regular),
                Text = "",
            };
            Controls.Add(_labelMeta);

            _labelDates = new Label
            {
                Name = "labelDates",
                Left = 656,
                Top = 402,
                Width = 494,
                Height = 250,
                Font = new Font("Times New Roman", 14, FontStyle.Regular),
                Text = "",
            };
            Controls.Add(_labelDates);
        }

        private async Task LoadMetaAsync()
        {
            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", UserSession.AccessToken);
                await LoadDeliveryTypesAsync(client);
                await LoadCitiesAsync(client);
            }
        }

        private async Task LoadDeliveryTypesAsync(HttpClient client)
        {
            var response = await client.GetAsync($"{ApiConfig.BaseUrl}/orders/meta/delivery_types");
            if (!response.IsSuccessStatusCode) return;
            var body = await response.Content.ReadAsStringAsync();
            var list = _serializer.DeserializeObject(body) as object[];
            _deliveryTypeMap.Clear();
            comboBox1.Items.Clear();
            if (list == null) return;
            foreach (var it in list)
            {
                var d = it as Dictionary<string, object>;
                if (d == null) continue;
                var id = Convert.ToInt32(d["id"]);
                var name = TranslateDeliveryType(Convert.ToString(d["name"]) ?? "");
                _deliveryTypeMap[name] = id;
                comboBox1.Items.Add(name);
            }
        }

        private async Task LoadStatusesAsync(HttpClient client, int? deliveryTypeId, string currentOrderStatus = null)
        {
            var sig = $"{deliveryTypeId?.ToString() ?? ""}|{currentOrderStatus ?? ""}";
            if (!_forceNextStatusesLoad && sig == _statusesCacheSignature && comboBox2.Items.Count > 0)
            {
                return;
            }
            _forceNextStatusesLoad = false;
            _statusesCacheSignature = sig;
            var url = $"{ApiConfig.BaseUrl}/orders/meta/statuses";
            if (deliveryTypeId.HasValue)
            {
                url += $"?delivery_type_id={deliveryTypeId.Value}";
                if (!string.IsNullOrWhiteSpace(currentOrderStatus))
                    url += $"&current_status={Uri.EscapeDataString(currentOrderStatus)}";
            }
            var response = await client.GetAsync(url);
            if (!response.IsSuccessStatusCode) return;
            var body = await response.Content.ReadAsStringAsync();
            var list = _serializer.DeserializeObject(body) as object[];
            _statusMap.Clear();
            comboBox2.Items.Clear();
            if (list == null) return;
            foreach (var it in list)
            {
                var s = it as Dictionary<string, object>;
                if (s == null) continue;
                var id = Convert.ToInt32(s["id"]);
                var raw = (Convert.ToString(s["name"]) ?? "").Trim();
                var nameRu = TranslateStatus(raw);
                _statusMap[nameRu] = id;
                comboBox2.Items.Add(nameRu);
            }
        }

        private async Task LoadCitiesAsync(HttpClient client)
        {
            var response = await client.GetAsync($"{ApiConfig.BaseUrl}/orders/meta/cities");
            if (!response.IsSuccessStatusCode) return;
            var body = await response.Content.ReadAsStringAsync();
            var list = _serializer.DeserializeObject(body) as object[];
            _cityMap.Clear();
            comboBox3.Items.Clear();
            if (list == null) return;
            foreach (var it in list)
            {
                var c = it as Dictionary<string, object>;
                if (c == null) continue;
                var id = Convert.ToInt32(c["id"]);
                var name = Convert.ToString(c["name"]) ?? $"Город {id}";
                _cityMap[name] = id;
                comboBox3.Items.Add(name);
            }
        }

        private async Task LoadPickupPointsAsync()
        {
            if (!_cityMap.TryGetValue(Convert.ToString(comboBox3.SelectedItem) ?? "", out var cityId)) return;
            await LoadPickupPointsByCityIdAsync(cityId);
        }

        private async Task LoadPickupPointsByCityIdAsync(int cityId)
        {
            _pickupMap.Clear();
            comboBox4.Items.Clear();
            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", UserSession.AccessToken);
                var response = await client.GetAsync($"{ApiConfig.BaseUrl}/orders/meta/pickup_points?city_id={cityId}");
                if (!response.IsSuccessStatusCode) return;
                var body = await response.Content.ReadAsStringAsync();
                var list = _serializer.DeserializeObject(body) as object[];
                if (list == null) return;
                foreach (var it in list)
                {
                    var p = it as Dictionary<string, object>;
                    if (p == null) continue;
                    var id = Convert.ToInt32(p["id"]);
                    var baseName = (Convert.ToString(p["name"]) ?? "").Trim();
                    if (string.IsNullOrEmpty(baseName)) baseName = $"ПВЗ {id}";
                    var display = $"{baseName} [#{id}]";
                    _pickupMap[display] = id;
                    comboBox4.Items.Add(display);
                }
            }
        }

        private async Task EnsurePickupSelectedAsync(string pickupIdText)
        {
            if (!int.TryParse(pickupIdText, out var pickupId)) return;
            if (_pickupMap.Values.Any(v => v == pickupId))
            {
                SelectComboByValue(comboBox4, _pickupMap, pickupIdText);
                return;
            }

            foreach (var city in _cityMap.OrderBy(kv => kv.Value))
            {
                SelectComboByValue(comboBox3, _cityMap, city.Value.ToString());
                await LoadPickupPointsByCityIdAsync(city.Value);
                if (_pickupMap.Values.Any(v => v == pickupId))
                {
                    SelectComboByValue(comboBox4, _pickupMap, pickupIdText);
                    return;
                }
            }
        }

        private async Task LoadOrderAsync()
        {
            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", UserSession.AccessToken);
                var response = await client.GetAsync($"{ApiConfig.BaseUrl}/orders/{OrderId}");
                if (!response.IsSuccessStatusCode)
                {
                    MessageBox.Show($"Ошибка загрузки заказа ({(int)response.StatusCode})");
                    return;
                }
                var body = await response.Content.ReadAsStringAsync();
                var order = _serializer.DeserializeObject(body) as Dictionary<string, object>;
                if (order == null) return;

                int? dtId = null;
                if (order.ContainsKey("delivery_type_id") && order["delivery_type_id"] != null
                    && int.TryParse(Convert.ToString(order["delivery_type_id"]), out var parsedDt))
                {
                    dtId = parsedDt;
                }
                var statusRaw = Convert.ToString(order.ContainsKey("status") ? order["status"] : "") ?? "";
                _forceNextStatusesLoad = true;
                await LoadStatusesAsync(client, dtId, statusRaw);

                _programmaticOrderLoad = true;
                try
                {
                    textBox1.Text = Convert.ToString(order.ContainsKey("id") ? order["id"] : "") ?? "";
                    textBox5.Text = Convert.ToString(order.ContainsKey("user_id") ? order["user_id"] : "") ?? "";
                    textBox2.Text = Convert.ToString(order.ContainsKey("shipping_address") ? order["shipping_address"] : "") ?? "";
                    numericUpDown1.Maximum = 100000000;
                    numericUpDown1.Value = ToDecimal(order, "total_amount");

                    SelectComboByValue(comboBox1, _deliveryTypeMap, Convert.ToString(order.ContainsKey("delivery_type_id") ? order["delivery_type_id"] : "") ?? "");
                    SelectComboByText(comboBox2, TranslateStatus(statusRaw));
                    var cityIdText = Convert.ToString(order.ContainsKey("city_id") ? order["city_id"] : "") ?? "";
                    var pickupIdText = Convert.ToString(order.ContainsKey("pickup_point_id") ? order["pickup_point_id"] : "") ?? "";
                    SelectComboByValue(comboBox3, _cityMap, cityIdText);
                    await LoadPickupPointsAsync();
                    await EnsurePickupSelectedAsync(pickupIdText);

                    var ps = (Convert.ToString(order.ContainsKey("payment_status") ? order["payment_status"] : "") ?? "").Trim();
                    checkBoxPaid.Checked = string.Equals(ps, "paid", StringComparison.OrdinalIgnoreCase);

                    RenderItems(order.ContainsKey("items") ? order["items"] as object[] : null);
                    RenderOrderMeta(order);
                    _buttonChange.Enabled = UserSession.UserRole == "admin" || UserSession.UserRole == "staff";
                }
                finally
                {
                    _programmaticOrderLoad = false;
                    ApplyDeliveryVisibility();
                }
            }
        }

        private void EnsureDeliveryStackOrigins()
        {
            if (_deliveryStackOrigTops != null) return;
            _deliveryStackOrigTops = new Dictionary<Control, int>();
            foreach (var c in new Control[] { label5, comboBox1, label6, numericUpDown1, checkBoxPaid, label4, comboBox3, label9, comboBox4 })
                _deliveryStackOrigTops[c] = c.Top;
            if (_buttonChange != null)
                _deliveryStackOrigTops[_buttonChange] = _buttonChange.Top;
        }

        private void ApplyDeliveryStackLayout(bool pickup)
        {
            EnsureDeliveryStackOrigins();
            const int margin = 12;
            var shift = 0;
            if (pickup)
            {
                var anchor = comboBox2.Bottom + margin;
                shift = anchor - _deliveryStackOrigTops[comboBox1];
            }
            foreach (var kv in _deliveryStackOrigTops)
                kv.Key.Top = kv.Value + shift;
        }

        private void ApplyDeliveryVisibility()
        {
            var delivery = Convert.ToString(comboBox1.SelectedItem) ?? "";
            var isPickup = delivery.ToLowerInvariant().Contains("самовывоз");
            label4.Visible = isPickup;
            comboBox3.Visible = isPickup;
            label9.Visible = isPickup;
            comboBox4.Visible = isPickup;
            label3.Visible = !isPickup;
            textBox2.Visible = !isPickup;
            ApplyDeliveryStackLayout(isPickup);
        }

        private void RenderItems(object[] items)
        {
            flowLayoutProducts.Controls.Clear();
            if (items == null || items.Length == 0)
            {
                flowLayoutProducts.Controls.Add(new Label { Text = "Товары не найдены", AutoSize = true });
                return;
            }
            foreach (var it in items)
            {
                var item = it as Dictionary<string, object>;
                if (item == null) continue;
                var panel = new Panel
                {
                    Width = 460,
                    Height = 66,
                    BorderStyle = BorderStyle.FixedSingle,
                    BackColor = Color.White,
                    Margin = new Padding(4),
                };
                var name = Convert.ToString(item.ContainsKey("product_name") ? item["product_name"] : "") ?? "-";
                var qty = Convert.ToString(item.ContainsKey("quantity") ? item["quantity"] : "") ?? "-";
                var price = Convert.ToString(item.ContainsKey("price") ? item["price"] : "") ?? "-";
                var total = Convert.ToString(item.ContainsKey("line_total") ? item["line_total"] : "") ?? "-";
                panel.Controls.Add(new Label { Left = 8, Top = 8, Width = 440, Height = 18, Font = new Font("Segoe UI", 9, FontStyle.Bold), Text = name });
                panel.Controls.Add(new Label { Left = 8, Top = 32, Width = 440, Height = 18, Text = $"Кол-во: {qty} | Цена: {price} | Сумма: {total}" });
                flowLayoutProducts.Controls.Add(panel);
            }
        }

        private void RenderOrderMeta(Dictionary<string, object> order)
        {
            var paymentStatus = TranslatePaymentStatus(Convert.ToString(order.ContainsKey("payment_status") ? order["payment_status"] : "") ?? "-");
            var paymentMethod = TranslatePaymentMethod(Convert.ToString(order.ContainsKey("payment_method") ? order["payment_method"] : "") ?? "-");
            _labelMeta.Text =
                $"Оплата: {paymentStatus} | Способ: {paymentMethod}\n" +
                $"Телефон: {Convert.ToString(order.ContainsKey("phone") ? order["phone"] : "") ?? "-"}";

            var createdAt = FormatDate(order, "created_at");
            var processedAt = FormatDate(order, "processed_at");
            var shippedAt = FormatDate(order, "shipped_at");
            var readyPickupAt = FormatDate(order, "ready_for_pickup_at");
            var deliveredAt = FormatDate(order, "delivered_at");
            var pickupAt = FormatDate(order, "pickup_at");
            var canceledAt = FormatDate(order, "canceled_at");
            var estimatedAt = FormatDate(order, "estimated_delivery_at");
            if (estimatedAt == "-")
                estimatedAt = FormatDate(order, "delivery_at");
            var paidAt = FormatDate(order, "paid_at");

            var deliveryTypeName = Convert.ToString(order.ContainsKey("delivery_type") ? order["delivery_type"] : "") ?? "";
            var isPickup = deliveryTypeName.ToLowerInvariant().Contains("самовывоз");

            var deliveredLine = isPickup ? "" : $"Доставлен курьером: {deliveredAt}\n";
            _labelDates.Text =
                $"Создан: {createdAt}\n" +
                $"В обработке: {processedAt}\n" +
                $"Отгружен: {shippedAt}\n" +
                $"Готов к выдаче: {readyPickupAt}\n" +
                deliveredLine +
                $"Выдан (самовывоз): {pickupAt}\n" +
                $"Отменен: {canceledAt}\n" +
                $"Плановая дата доставки: {estimatedAt}\n" +
                $"Оплачен: {paidAt}";
        }

        private async void buttonChange_Click(object sender, EventArgs e)
        {
            if (UserSession.UserRole != "admin" && UserSession.UserRole != "staff")
            {
                MessageBox.Show("Изменение заказа доступно только администратору или сотруднику");
                return;
            }
            var deliveryName = Convert.ToString(comboBox1.SelectedItem) ?? "";
            var statusName = Convert.ToString(comboBox2.SelectedItem) ?? "";
            if (!_deliveryTypeMap.ContainsKey(deliveryName) || !_statusMap.ContainsKey(statusName))
            {
                MessageBox.Show("Выбери тип доставки и статус");
                return;
            }
            var isPickup = deliveryName.ToLowerInvariant().Contains("самовывоз");
            int? cityId = null;
            int? pickupId = null;
            string address = textBox2.Text.Trim();
            if (isPickup)
            {
                var cityName = Convert.ToString(comboBox3.SelectedItem) ?? "";
                var pickupName = Convert.ToString(comboBox4.SelectedItem) ?? "";
                if (!_cityMap.ContainsKey(cityName) || !_pickupMap.ContainsKey(pickupName))
                {
                    MessageBox.Show("Для самовывоза выбери город и пункт выдачи");
                    return;
                }
                cityId = _cityMap[cityName];
                pickupId = _pickupMap[pickupName];
            }

            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", UserSession.AccessToken);
                var paymentStatus = checkBoxPaid.Checked ? "paid" : "pending";
                var payload = _serializer.Serialize(
                    new
                    {
                        status_id = _statusMap[statusName],
                        delivery_type_id = _deliveryTypeMap[deliveryName],
                        shipping_address = address,
                        city_id = cityId,
                        pickup_point_id = pickupId,
                        payment_status = paymentStatus,
                    }
                );
                var request = new HttpRequestMessage(new HttpMethod("PATCH"), $"{ApiConfig.BaseUrl}/orders/{OrderId}")
                {
                    Content = new StringContent(payload, Encoding.UTF8, "application/json"),
                };
                var response = await client.SendAsync(request);
                if (!response.IsSuccessStatusCode)
                {
                    var errBody = await response.Content.ReadAsStringAsync();
                    MessageBox.Show(
                        string.IsNullOrWhiteSpace(errBody)
                            ? $"Ошибка изменения заказа ({(int)response.StatusCode})"
                            : $"Ошибка ({(int)response.StatusCode})\n{errBody}");
                    return;
                }
            }
            MessageBox.Show("Заказ обновлен");
            await LoadOrderAsync();
        }

        private static decimal ToDecimal(Dictionary<string, object> source, string key)
        {
            if (!source.ContainsKey(key) || source[key] == null) return 0;
            decimal.TryParse(Convert.ToString(source[key]), out var value);
            return value;
        }

        private static void SelectComboByValue(ComboBox combo, Dictionary<string, int> map, string idText)
        {
            if (!int.TryParse(idText, out var id)) return;
            foreach (var kv in map)
            {
                if (kv.Value == id)
                {
                    combo.SelectedItem = kv.Key;
                    return;
                }
            }
        }

        private static void SelectComboByText(ComboBox combo, string text)
        {
            if (combo.Items.Contains(text))
            {
                combo.SelectedItem = text;
            }
        }

        private static string TranslateStatus(string status)
        {
            switch ((status ?? string.Empty).Trim().ToLowerInvariant())
            {
                case "pending":
                    return "Ожидает";
                case "processing":
                    return "В обработке";
                case "shipped":
                    return "Отгружен";
                case "in_transit":
                    return "В пути";
                case "delivered":
                    return "Доставлен";
                case "pickup":
                    return "Выдан";
                case "ready_for_pickup":
                    return "Готов к выдаче";
                case "canceled":
                case "cancelled":
                    return "Отменен";
                default:
                    return string.IsNullOrWhiteSpace(status) ? "-" : status;
            }
        }

        private static string TranslateDeliveryType(string deliveryType)
        {
            var text = (deliveryType ?? "").Trim();
            if (text.Contains("Самовывоз")) return "Самовывоз";
            if (text.Contains("Курьер")) return "Курьер";
            return text;
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

        private static string TranslatePaymentMethod(string method)
        {
            switch ((method ?? string.Empty).Trim().ToLowerInvariant())
            {
                case "cash":
                    return "Наличными";
                case "card":
                    return "Картой";
                default:
                    return string.IsNullOrWhiteSpace(method) ? "-" : method;
            }
        }

        private static string FormatDate(Dictionary<string, object> source, string key)
        {
            var raw = Convert.ToString(source.ContainsKey(key) ? source[key] : "") ?? "";
            if (string.IsNullOrWhiteSpace(raw)) return "-";
            if (DateTime.TryParse(raw, out var dt))
            {
                return dt.ToString("dd.MM.yyyy HH:mm");
            }
            return raw;
        }
	}
}
