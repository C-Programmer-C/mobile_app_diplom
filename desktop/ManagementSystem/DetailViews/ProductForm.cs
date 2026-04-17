using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Windows.Forms;

namespace ManagementSystem.DetailViews
{
    public partial class ProductForm: Form
    {
        public int ProductId { get; set; }
        public bool IsCreateMode { get; set; }
        private readonly JavaScriptSerializer _serializer = new JavaScriptSerializer();
        private readonly Dictionary<string, int> _categoryMap = new Dictionary<string, int>();
        private readonly Dictionary<string, int> _brandMap = new Dictionary<string, int>();
        private string _currentImagePath = string.Empty;
        private bool _imageMarkedForDelete;

        public ProductForm()
        {
            InitializeComponent();
        }

		private void ProductForm_FormClosing(object sender, FormClosingEventArgs e)
		{
			this.Close();
		}

		private async void ProductForm_Load(object sender, EventArgs e)
		{
            comboBox2.DropDownStyle = ComboBoxStyle.DropDownList;
            comboBox1.DropDownStyle = ComboBoxStyle.DropDownList;
            numericUpDown1.Maximum = 100000000;
            numericUpDown2.Maximum = 1000000;
            numericUpDown3.Maximum = 100000000;
            numericUpDown4.Maximum = 1000000;
            numericUpDown5.Maximum = 1000000;
            numericUpDown6.Maximum = 100000000;
            buttonLoadPhoto.Click += buttonUpload_Click;
            buttonDeletePhoto.Click += buttonDeleteImage_Click;
            buttonCancel.Click += buttonBack_Click;
            buttonChange.Click += buttonSave_Click;
            try
            {
                if (IsCreateMode)
                {
                    await LoadCategoriesAsync();
                    await LoadBrandsAsync();
                    SetupCreateModeUi();
                    return;
                }
                await LoadProductAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка загрузки карточки товара: {ex.Message}");
            }
		}

        private async Task LoadProductAsync()
        {
            await LoadCategoriesAsync();
            await LoadBrandsAsync();
            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", UserSession.AccessToken);
                var response = await client.GetAsync($"{ApiConfig.BaseUrl}/products/{ProductId}/details");
                if (!response.IsSuccessStatusCode)
                {
                    MessageBox.Show($"Ошибка загрузки товара ({(int)response.StatusCode})");
                    return;
                }

                var json = await response.Content.ReadAsStringAsync();
                var product = _serializer.DeserializeObject(json) as Dictionary<string, object>;
                if (product == null) return;

                textBox1.Text = Convert.ToString(product.ContainsKey("id") ? product["id"] : "") ?? "";
                numericUpDown1.Value = ToDecimal(product, "price");
                textBox2.Text = Convert.ToString(product.ContainsKey("name") ? product["name"] : "") ?? "";
                textBox5.Text = Convert.ToString(product.ContainsKey("description") ? product["description"] : "") ?? "";
                textBox6.Text = Convert.ToString(product.ContainsKey("specifications") ? product["specifications"] : "") ?? "";
                textBox7.Text = Convert.ToString(product.ContainsKey("warranty") ? product["warranty"] : "") ?? "";
                textBox8.Text = Convert.ToString(product.ContainsKey("color") ? product["color"] : "") ?? "";
                textBox3.Text = Convert.ToString(product.ContainsKey("dimensions") ? product["dimensions"] : "") ?? "";
                textBox9.Text = Convert.ToString(product.ContainsKey("weight") ? product["weight"] : "") ?? "";
                checkBox1.Checked = ToBool(product, "is_new");
                checkBox2.Checked = ToBool(product, "is_popular");
                numericUpDown2.Value = ToDecimal(product, "discount");
                numericUpDown3.Value = ToDecimal(product, "quantity");
                numericUpDown4.Value = ToDecimal(product, "rating");
                numericUpDown5.Value = ToDecimal(product, "count_feedbacks");
                numericUpDown6.Value = ToDecimal(product, "sold_count");

                var categoryId = Convert.ToString(product.ContainsKey("category_id") ? product["category_id"] : "") ?? "";
                SelectComboById(comboBox2, _categoryMap, categoryId);
                var brandId = Convert.ToString(product.ContainsKey("brand_id") ? product["brand_id"] : "") ?? "";
                SelectComboById(comboBox1, _brandMap, brandId);

                _currentImagePath = Convert.ToString(product.ContainsKey("image_url") ? product["image_url"] : "") ?? "";
                _imageMarkedForDelete = false;
                await LoadImageAsync(_currentImagePath);
                ApplyAccessByRole();
            }
        }

        private async Task LoadCategoriesAsync()
        {
            using (var client = new HttpClient())
            {
                var response = await client.GetAsync($"{ApiConfig.BaseUrl}/products/categories");
                if (!response.IsSuccessStatusCode) return;
                var json = await response.Content.ReadAsStringAsync();
                var list = _serializer.DeserializeObject(json) as object[];
                comboBox2.Items.Clear();
                _categoryMap.Clear();
                if (list == null) return;
                foreach (var item in list)
                {
                    var c = item as Dictionary<string, object>;
                    if (c == null) continue;
                    var id = Convert.ToInt32(c["id"]);
                    var name = Convert.ToString(c["name"]) ?? $"Category {id}";
                    _categoryMap[name] = id;
                    comboBox2.Items.Add(name);
                }
            }
        }

        private async Task LoadBrandsAsync()
        {
            using (var client = new HttpClient())
            {
                var response = await client.GetAsync($"{ApiConfig.BaseUrl}/products/brands");
                if (!response.IsSuccessStatusCode) return;
                var json = await response.Content.ReadAsStringAsync();
                var list = _serializer.DeserializeObject(json) as object[];
                comboBox1.Items.Clear();
                _brandMap.Clear();
                if (list == null) return;
                foreach (var item in list)
                {
                    var b = item as Dictionary<string, object>;
                    if (b == null) continue;
                    var id = Convert.ToInt32(b["id"]);
                    var name = Convert.ToString(b["name"]) ?? $"Brand {id}";
                    _brandMap[name] = id;
                    comboBox1.Items.Add(name);
                }
            }
        }

        private async Task LoadImageAsync(string imageUrl)
        {
            pictureBox1.Image = null;
            if (string.IsNullOrWhiteSpace(imageUrl)) return;
            try
            {
                using (var client = new HttpClient())
                {
                    var bytes = await client.GetByteArrayAsync(imageUrl);
                    using (var ms = new MemoryStream(bytes))
                    {
                        pictureBox1.SizeMode = PictureBoxSizeMode.Zoom;
                        pictureBox1.Image = Image.FromStream(ms);
                    }
                }
            }
            catch
            {
                pictureBox1.BackColor = Color.Gainsboro;
            }
        }

        private void ApplyAccessByRole()
        {
            var canEdit = UserSession.UserRole == "admin" || UserSession.UserRole == "staff";
            textBox2.Enabled = canEdit;
            textBox5.Enabled = canEdit;
            textBox6.Enabled = canEdit;
            textBox7.Enabled = canEdit;
            textBox8.Enabled = canEdit;
            textBox3.Enabled = canEdit;
            textBox9.Enabled = canEdit;
            comboBox1.Enabled = canEdit;
            comboBox2.Enabled = canEdit;
            numericUpDown1.Enabled = canEdit;
            numericUpDown2.Enabled = canEdit;
            numericUpDown3.Enabled = canEdit;
            checkBox1.Enabled = canEdit;
            checkBox2.Enabled = canEdit;
            buttonDeletePhoto.Enabled = canEdit;
            buttonLoadPhoto.Enabled = canEdit;
            buttonChange.Enabled = canEdit;
        }

        private async void buttonSave_Click(object sender, EventArgs e)
        {
            if (UserSession.UserRole != "admin" && UserSession.UserRole != "staff")
            {
                MessageBox.Show("Изменение товара доступно только администратору или сотруднику");
                return;
            }
            if (IsCreateMode)
            {
                await CreateProductAsync();
                return;
            }
            var categoryName = Convert.ToString(comboBox2.SelectedItem) ?? string.Empty;
            var brandName = Convert.ToString(comboBox1.SelectedItem) ?? string.Empty;
            if (!_categoryMap.ContainsKey(categoryName) || !_brandMap.ContainsKey(brandName))
            {
                MessageBox.Show("Выбери категорию и бренд");
                return;
            }

            var payload = _serializer.Serialize(
                new
                {
                    category_id = _categoryMap[categoryName],
                    brand_id = _brandMap[brandName],
                    price = Convert.ToDouble(numericUpDown1.Value),
                    name = textBox2.Text.Trim(),
                    description = textBox5.Text.Trim(),
                    specifications = textBox6.Text.Trim(),
                    warranty = ParseInt(textBox7.Text),
                    color = textBox8.Text.Trim(),
                    dimensions = textBox3.Text.Trim(),
                    weight = textBox9.Text.Trim(),
                    is_new = checkBox1.Checked,
                    is_popular = checkBox2.Checked,
                    discount = Convert.ToDouble(numericUpDown2.Value),
                    quantity = Convert.ToInt32(numericUpDown3.Value),
                }
            );

            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", UserSession.AccessToken);
                var request = new HttpRequestMessage(new HttpMethod("PATCH"), $"{ApiConfig.BaseUrl}/products/{ProductId}")
                {
                    Content = new StringContent(payload, Encoding.UTF8, "application/json"),
                };
                var response = await client.SendAsync(request);
                if (!response.IsSuccessStatusCode)
                {
                    MessageBox.Show($"Ошибка изменения товара ({(int)response.StatusCode})");
                    return;
                }

                if (_imageMarkedForDelete)
                {
                    var deleteResponse = await client.DeleteAsync($"{ApiConfig.BaseUrl}/products/{ProductId}/image");
                    if (!deleteResponse.IsSuccessStatusCode)
                    {
                        MessageBox.Show($"Ошибка удаления изображения ({(int)deleteResponse.StatusCode})");
                        return;
                    }
                }
            }

            MessageBox.Show("Товар обновлен");
            await LoadProductAsync();
        }

        private async void buttonUpload_Click(object sender, EventArgs e)
        {
            if (UserSession.UserRole != "admin" && UserSession.UserRole != "staff")
            {
                MessageBox.Show("Загрузка изображения доступна только администратору или сотруднику");
                return;
            }
            using (var dialog = new OpenFileDialog())
            {
                dialog.Filter = "Image Files|*.jpg;*.jpeg;*.png;*.webp";
                if (dialog.ShowDialog() != DialogResult.OK) return;
                if (IsCreateMode)
                {
                    _currentImagePath = dialog.FileName;
                    pictureBox1.SizeMode = PictureBoxSizeMode.Zoom;
                    pictureBox1.Image = Image.FromFile(dialog.FileName);
                    return;
                }
                using (var client = new HttpClient())
                using (var formData = new MultipartFormDataContent())
                {
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", UserSession.AccessToken);
                    var bytes = File.ReadAllBytes(dialog.FileName);
                    var content = new ByteArrayContent(bytes);
                    content.Headers.ContentType = MediaTypeHeaderValue.Parse("application/octet-stream");
                    formData.Add(content, "file", Path.GetFileName(dialog.FileName));
                    var response = await client.PostAsync($"{ApiConfig.BaseUrl}/products/{ProductId}/image", formData);
                    if (!response.IsSuccessStatusCode)
                    {
                        MessageBox.Show($"Ошибка загрузки изображения ({(int)response.StatusCode})");
                        return;
                    }
                }
            }
            await LoadProductAsync();
        }

        private void buttonDeleteImage_Click(object sender, EventArgs e)
        {
            if (UserSession.UserRole != "admin" && UserSession.UserRole != "staff")
            {
                MessageBox.Show("Удаление изображения доступно только администратору или сотруднику");
                return;
            }
            pictureBox1.Image = null;
            _currentImagePath = string.Empty;
            _imageMarkedForDelete = !IsCreateMode;
        }

        private void buttonBack_Click(object sender, EventArgs e)
        {
            Hide();
            new ProductsForm().Show();
        }

        private static void SelectComboById(ComboBox combo, Dictionary<string, int> map, string idText)
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

        private static decimal ToDecimal(Dictionary<string, object> source, string key)
        {
            if (!source.ContainsKey(key) || source[key] == null) return 0;
            decimal.TryParse(Convert.ToString(source[key]), out var value);
            return value;
        }

        private static bool ToBool(Dictionary<string, object> source, string key)
        {
            if (!source.ContainsKey(key) || source[key] == null) return false;
            var val = Convert.ToString(source[key]) ?? "";
            return val.Equals("true", StringComparison.OrdinalIgnoreCase) || val == "1";
        }

        private static int ParseInt(string value)
        {
            return int.TryParse((value ?? "").Trim(), out var n) ? n : 0;
        }

        private void SetupCreateModeUi()
        {
            label1.Text = "Создание товара";
            buttonChange.Text = "Создать";
            textBox1.Text = "";
            textBox1.Enabled = false;
            dateTimePicker1.Value = DateTime.Now;
            dateTimePicker1.Enabled = false;
            numericUpDown4.Value = 0;
            numericUpDown5.Value = 0;
            numericUpDown6.Value = 0;
            pictureBox1.Image = null;
            _currentImagePath = string.Empty;
            _imageMarkedForDelete = false;
            ApplyAccessByRole();
        }

        private async Task CreateProductAsync()
        {
            var categoryName = Convert.ToString(comboBox2.SelectedItem) ?? string.Empty;
            var brandName = Convert.ToString(comboBox1.SelectedItem) ?? string.Empty;
            if (!_categoryMap.ContainsKey(categoryName) || !_brandMap.ContainsKey(brandName))
            {
                MessageBox.Show("Выбери категорию и бренд");
                return;
            }
            var payload = _serializer.Serialize(
                new
                {
                    category_id = _categoryMap[categoryName],
                    brand_id = _brandMap[brandName],
                    price = Convert.ToDouble(numericUpDown1.Value),
                    name = textBox2.Text.Trim(),
                    description = textBox5.Text.Trim(),
                    specifications = textBox6.Text.Trim(),
                    warranty = ParseInt(textBox7.Text),
                    color = textBox8.Text.Trim(),
                    dimensions = textBox3.Text.Trim(),
                    weight = textBox9.Text.Trim(),
                    is_new = checkBox1.Checked,
                    is_popular = checkBox2.Checked,
                    discount = Convert.ToDouble(numericUpDown2.Value),
                    quantity = Convert.ToInt32(numericUpDown3.Value),
                    image_url = _currentImagePath,
                }
            );
            int createdId;
            using (var client = new HttpClient())
            {
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", UserSession.AccessToken);
                var response = await client.PostAsync(
                    $"{ApiConfig.BaseUrl}/products/",
                    new StringContent(payload, Encoding.UTF8, "application/json")
                );
                if (!response.IsSuccessStatusCode)
                {
                    MessageBox.Show($"Ошибка создания товара ({(int)response.StatusCode})");
                    return;
                }
                var json = await response.Content.ReadAsStringAsync();
                var data = _serializer.DeserializeObject(json) as Dictionary<string, object>;
                createdId = data != null && data.ContainsKey("id") ? Convert.ToInt32(data["id"]) : 0;
            }

            if (createdId > 0 && !string.IsNullOrWhiteSpace(_currentImagePath) && File.Exists(_currentImagePath))
            {
                using (var client = new HttpClient())
                using (var formData = new MultipartFormDataContent())
                {
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", UserSession.AccessToken);
                    var bytes = File.ReadAllBytes(_currentImagePath);
                    var content = new ByteArrayContent(bytes);
                    content.Headers.ContentType = MediaTypeHeaderValue.Parse("application/octet-stream");
                    formData.Add(content, "file", Path.GetFileName(_currentImagePath));
                    await client.PostAsync($"{ApiConfig.BaseUrl}/products/{createdId}/image", formData);
                }
            }

            MessageBox.Show("Товар создан");
            Hide();
            new ProductsForm().Show();
        }

		private void buttonDeletePhoto_Click(object sender, EventArgs e)
		{
            buttonDeleteImage_Click(sender, e);
		}

		private void buttonCancel_Click(object sender, EventArgs e)
		{

		}
	}
}
