namespace ManagementSystem
{
	partial class MenuForm
	{
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.IContainer components = null;

		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		/// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
		protected override void Dispose(bool disposing)
		{
			if (disposing && (components != null))
			{
				components.Dispose();
			}
			base.Dispose(disposing);
		}

		#region Windows Form Designer generated code

		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{
			System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(MenuForm));
			this.buttonProducts = new System.Windows.Forms.Button();
			this.panel1 = new System.Windows.Forms.Panel();
			this.buttonStaffs = new System.Windows.Forms.Button();
			this.buttonOrders = new System.Windows.Forms.Button();
			this.buttonClients = new System.Windows.Forms.Button();
			this.label1 = new System.Windows.Forms.Label();
			this.labelName = new System.Windows.Forms.Label();
			this.labelRole = new System.Windows.Forms.Label();
			this.button1 = new System.Windows.Forms.Button();
			this.panel1.SuspendLayout();
			this.SuspendLayout();
			// 
			// buttonProducts
			// 
			this.buttonProducts.Font = new System.Drawing.Font("Times New Roman", 20.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.buttonProducts.Location = new System.Drawing.Point(21, 14);
			this.buttonProducts.Name = "buttonProducts";
			this.buttonProducts.Size = new System.Drawing.Size(144, 67);
			this.buttonProducts.TabIndex = 0;
			this.buttonProducts.Text = "Товары";
			this.buttonProducts.UseVisualStyleBackColor = true;
			this.buttonProducts.Click += new System.EventHandler(this.buttonProducts_Click);
			// 
			// panel1
			// 
			this.panel1.BackColor = System.Drawing.SystemColors.ScrollBar;
			this.panel1.Controls.Add(this.button1);
			this.panel1.Controls.Add(this.buttonStaffs);
			this.panel1.Controls.Add(this.buttonOrders);
			this.panel1.Controls.Add(this.buttonClients);
			this.panel1.Controls.Add(this.buttonProducts);
			this.panel1.Location = new System.Drawing.Point(12, 63);
			this.panel1.Name = "panel1";
			this.panel1.Size = new System.Drawing.Size(722, 338);
			this.panel1.TabIndex = 1;
			// 
			// buttonStaffs
			// 
			this.buttonStaffs.Font = new System.Drawing.Font("Times New Roman", 20.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.buttonStaffs.Location = new System.Drawing.Point(261, 234);
			this.buttonStaffs.Name = "buttonStaffs";
			this.buttonStaffs.Size = new System.Drawing.Size(166, 67);
			this.buttonStaffs.TabIndex = 3;
			this.buttonStaffs.Text = "Сотрудники";
			this.buttonStaffs.UseVisualStyleBackColor = true;
			this.buttonStaffs.Click += new System.EventHandler(this.buttonStaffs_Click);
			// 
			// buttonOrders
			// 
			this.buttonOrders.Font = new System.Drawing.Font("Times New Roman", 20.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.buttonOrders.Location = new System.Drawing.Point(549, 14);
			this.buttonOrders.Name = "buttonOrders";
			this.buttonOrders.Size = new System.Drawing.Size(144, 67);
			this.buttonOrders.TabIndex = 2;
			this.buttonOrders.Text = "Заказы";
			this.buttonOrders.UseVisualStyleBackColor = true;
			this.buttonOrders.Click += new System.EventHandler(this.buttonOrders_Click);
			// 
			// buttonClients
			// 
			this.buttonClients.Font = new System.Drawing.Font("Times New Roman", 20.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.buttonClients.Location = new System.Drawing.Point(274, 14);
			this.buttonClients.Name = "buttonClients";
			this.buttonClients.Size = new System.Drawing.Size(144, 67);
			this.buttonClients.TabIndex = 1;
			this.buttonClients.Text = "Клиенты";
			this.buttonClients.UseVisualStyleBackColor = true;
			this.buttonClients.Click += new System.EventHandler(this.buttonClients_Click);
			// 
			// label1
			// 
			this.label1.AutoSize = true;
			this.label1.Font = new System.Drawing.Font("Microsoft YaHei UI", 20.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.label1.Location = new System.Drawing.Point(308, 9);
			this.label1.Name = "label1";
			this.label1.Size = new System.Drawing.Size(103, 36);
			this.label1.TabIndex = 2;
			this.label1.Text = "Меню";
			// 
			// labelName
			// 
			this.labelName.Font = new System.Drawing.Font("Microsoft YaHei UI", 15.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.labelName.ImageAlign = System.Drawing.ContentAlignment.MiddleLeft;
			this.labelName.Location = new System.Drawing.Point(491, 16);
			this.labelName.Name = "labelName";
			this.labelName.Size = new System.Drawing.Size(243, 36);
			this.labelName.TabIndex = 3;
			this.labelName.Text = "Имя:";
			this.labelName.TextAlign = System.Drawing.ContentAlignment.TopRight;
			// 
			// labelRole
			// 
			this.labelRole.AutoSize = true;
			this.labelRole.Font = new System.Drawing.Font("Microsoft YaHei UI", 15.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.labelRole.Location = new System.Drawing.Point(12, 16);
			this.labelRole.Name = "labelRole";
			this.labelRole.Size = new System.Drawing.Size(67, 28);
			this.labelRole.TabIndex = 4;
			this.labelRole.Text = "Роль:";
			this.labelRole.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
			// 
			// button1
			// 
			this.button1.Font = new System.Drawing.Font("Times New Roman", 20.25F);
			this.button1.Location = new System.Drawing.Point(34, 234);
			this.button1.Name = "button1";
			this.button1.Size = new System.Drawing.Size(131, 67);
			this.button1.TabIndex = 4;
			this.button1.Text = "Выйти";
			this.button1.UseVisualStyleBackColor = true;
			this.button1.Click += new System.EventHandler(this.button1_Click);
			// 
			// MenuForm
			// 
			this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
			this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			this.ClientSize = new System.Drawing.Size(740, 413);
			this.Controls.Add(this.labelRole);
			this.Controls.Add(this.labelName);
			this.Controls.Add(this.label1);
			this.Controls.Add(this.panel1);
			this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
			this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
			this.Name = "MenuForm";
			this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.MenuForm_FormClosing);
			this.Load += new System.EventHandler(this.MenuForm_Load);
			this.panel1.ResumeLayout(false);
			this.ResumeLayout(false);
			this.PerformLayout();

		}

		#endregion

		private System.Windows.Forms.Button buttonProducts;
		private System.Windows.Forms.Panel panel1;
		private System.Windows.Forms.Button buttonOrders;
		private System.Windows.Forms.Button buttonClients;
		private System.Windows.Forms.Label label1;
		private System.Windows.Forms.Button buttonStaffs;
		private System.Windows.Forms.Label labelName;
		private System.Windows.Forms.Label labelRole;
		private System.Windows.Forms.Button button1;
	}
}