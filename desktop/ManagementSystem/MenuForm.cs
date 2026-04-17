using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace ManagementSystem
{
    public partial class MenuForm: Form
    {
        public string UserRole { get; set; }
		public string UserName { get; set; }

        public MenuForm()
        {
            InitializeComponent();
        }

		private void MenuForm_Load(object sender, EventArgs e)
		{
            if (string.IsNullOrWhiteSpace(UserRole))
            {
                UserRole = UserSession.UserRole;
            }
            if (string.IsNullOrWhiteSpace(UserName))
            {
                UserName = UserSession.UserName;
            }
            var roleText = string.IsNullOrWhiteSpace(UserRole) ? "-" : UserRole;
            var nameText = string.IsNullOrWhiteSpace(UserName) ? "-" : UserName;


            if (roleText == "admin")
            {
                roleText = "Администратор";
            }
            else if (roleText == "staff") 
            {
				roleText = "Сотрудник";
                buttonStaffs.Visible = false;
			}

                labelRole.Text = $"Роль: {roleText}";
            labelName.Text = $"Имя: {nameText}";
		}

		private void MenuForm_FormClosing(object sender, FormClosingEventArgs e)
		{
			this.Close();
		}

		private void buttonProducts_Click(object sender, EventArgs e)
		{
			this.Hide();
			ProductsForm productsForm = new ProductsForm();
            productsForm.Show();
		}

		private void buttonClients_Click(object sender, EventArgs e)
		{
			this.Hide();
			ClientsForm clientsForm = new ClientsForm
			{
                ViewMode = "clients",
            };
            clientsForm.Show();
		}

		private void buttonOrders_Click(object sender, EventArgs e)
		{
			this.Hide();
			OrdersForm ordersForm = new OrdersForm();
            ordersForm.Show();
		}

		private void buttonStaffs_Click(object sender, EventArgs e)
		{
            this.Hide();
            ClientsForm clientsForm = new ClientsForm
            {
                ViewMode = "staffs",
            };
            clientsForm.Show();
            
		}

		private void button1_Click(object sender, EventArgs e)
		{
            UserSession.AccessToken = null;
            UserSession.UserName = null;
            UserSession.UserRole = null;
            this.Hide();
            AuthForm form = new AuthForm();
            form.Show();
        }
    }
}
