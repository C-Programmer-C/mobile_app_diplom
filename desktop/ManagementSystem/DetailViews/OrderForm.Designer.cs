namespace ManagementSystem.DetailViews
{
	partial class OrderForm
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
			System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(OrderForm));
			this.label1 = new System.Windows.Forms.Label();
			this.flowLayoutProducts = new System.Windows.Forms.FlowLayoutPanel();
			this.labelComments = new System.Windows.Forms.Label();
			this.comboBox1 = new System.Windows.Forms.ComboBox();
			this.textBox1 = new System.Windows.Forms.TextBox();
			this.label6 = new System.Windows.Forms.Label();
			this.label5 = new System.Windows.Forms.Label();
			this.label2 = new System.Windows.Forms.Label();
			this.textBox5 = new System.Windows.Forms.TextBox();
			this.label7 = new System.Windows.Forms.Label();
			this.comboBox2 = new System.Windows.Forms.ComboBox();
			this.label8 = new System.Windows.Forms.Label();
			this.label3 = new System.Windows.Forms.Label();
			this.textBox2 = new System.Windows.Forms.TextBox();
			this.comboBox3 = new System.Windows.Forms.ComboBox();
			this.label4 = new System.Windows.Forms.Label();
			this.label9 = new System.Windows.Forms.Label();
			this.comboBox4 = new System.Windows.Forms.ComboBox();
			this.numericUpDown1 = new System.Windows.Forms.NumericUpDown();
			this.checkBoxPaid = new System.Windows.Forms.CheckBox();
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown1)).BeginInit();
			this.SuspendLayout();
			// 
			// label1
			// 
			this.label1.AutoSize = true;
			this.label1.Font = new System.Drawing.Font("Microsoft YaHei UI", 20.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.label1.Location = new System.Drawing.Point(210, 21);
			this.label1.Name = "label1";
			this.label1.Size = new System.Drawing.Size(332, 36);
			this.label1.TabIndex = 6;
			this.label1.Text = "Информация о заказе";
			// 
			// flowLayoutProducts
			// 
			this.flowLayoutProducts.AutoScroll = true;
			this.flowLayoutProducts.BackColor = System.Drawing.SystemColors.ControlLight;
			this.flowLayoutProducts.Location = new System.Drawing.Point(656, 69);
			this.flowLayoutProducts.Name = "flowLayoutProducts";
			this.flowLayoutProducts.Padding = new System.Windows.Forms.Padding(8);
			this.flowLayoutProducts.Size = new System.Drawing.Size(494, 228);
			this.flowLayoutProducts.TabIndex = 7;
			this.flowLayoutProducts.WrapContents = false;
			// 
			// labelComments
			// 
			this.labelComments.AutoSize = true;
			this.labelComments.Font = new System.Drawing.Font("Microsoft YaHei UI", 20.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.labelComments.Location = new System.Drawing.Point(849, 21);
			this.labelComments.Name = "labelComments";
			this.labelComments.Size = new System.Drawing.Size(124, 36);
			this.labelComments.TabIndex = 23;
			this.labelComments.Text = "Товары";
			this.labelComments.Visible = false;
			// 
			// comboBox1
			// 
			this.comboBox1.Enabled = false;
			this.comboBox1.Font = new System.Drawing.Font("Times New Roman", 15.75F);
			this.comboBox1.FormattingEnabled = true;
			this.comboBox1.Location = new System.Drawing.Point(196, 330);
			this.comboBox1.Name = "comboBox1";
			this.comboBox1.Size = new System.Drawing.Size(348, 31);
			this.comboBox1.TabIndex = 33;
			this.comboBox1.SelectedIndexChanged += new System.EventHandler(this.comboBox1_SelectedIndexChanged);
			// 
			// textBox1
			// 
			this.textBox1.Enabled = false;
			this.textBox1.Font = new System.Drawing.Font("Times New Roman", 15.75F);
			this.textBox1.Location = new System.Drawing.Point(194, 85);
			this.textBox1.Name = "textBox1";
			this.textBox1.Size = new System.Drawing.Size(348, 32);
			this.textBox1.TabIndex = 29;
			// 
			// label6
			// 
			this.label6.AutoSize = true;
			this.label6.Font = new System.Drawing.Font("Times New Roman", 15.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.label6.Location = new System.Drawing.Point(120, 375);
			this.label6.Name = "label6";
			this.label6.Size = new System.Drawing.Size(48, 23);
			this.label6.TabIndex = 28;
			this.label6.Text = "Имя";
			// 
			// label5
			// 
			this.label5.AutoSize = true;
			this.label5.Font = new System.Drawing.Font("Times New Roman", 15.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.label5.Location = new System.Drawing.Point(53, 330);
			this.label5.Name = "label5";
			this.label5.Size = new System.Drawing.Size(129, 23);
			this.label5.TabIndex = 27;
			this.label5.Text = "Тип доставки";
			// 
			// label2
			// 
			this.label2.AutoSize = true;
			this.label2.Font = new System.Drawing.Font("Times New Roman", 15.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.label2.Location = new System.Drawing.Point(95, 88);
			this.label2.Name = "label2";
			this.label2.Size = new System.Drawing.Size(87, 23);
			this.label2.TabIndex = 24;
			this.label2.Text = "Id Заказа";
			// 
			// textBox5
			// 
			this.textBox5.Enabled = false;
			this.textBox5.Font = new System.Drawing.Font("Times New Roman", 15.75F);
			this.textBox5.Location = new System.Drawing.Point(194, 130);
			this.textBox5.Name = "textBox5";
			this.textBox5.Size = new System.Drawing.Size(348, 32);
			this.textBox5.TabIndex = 35;
			// 
			// label7
			// 
			this.label7.AutoSize = true;
			this.label7.Font = new System.Drawing.Font("Times New Roman", 15.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.label7.Location = new System.Drawing.Point(78, 133);
			this.label7.Name = "label7";
			this.label7.Size = new System.Drawing.Size(104, 23);
			this.label7.TabIndex = 34;
			this.label7.Text = "Id Клиента";
			// 
			// comboBox2
			// 
			this.comboBox2.Font = new System.Drawing.Font("Times New Roman", 15.75F);
			this.comboBox2.FormattingEnabled = true;
			this.comboBox2.Location = new System.Drawing.Point(194, 171);
			this.comboBox2.Name = "comboBox2";
			this.comboBox2.Size = new System.Drawing.Size(348, 31);
			this.comboBox2.TabIndex = 37;
			// 
			// label8
			// 
			this.label8.AutoSize = true;
			this.label8.Font = new System.Drawing.Font("Times New Roman", 15.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.label8.Location = new System.Drawing.Point(28, 174);
			this.label8.Name = "label8";
			this.label8.Size = new System.Drawing.Size(154, 23);
			this.label8.TabIndex = 36;
			this.label8.Text = "Статус доставки";
			// 
			// label3
			// 
			this.label3.AutoSize = true;
			this.label3.Font = new System.Drawing.Font("Times New Roman", 15.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.label3.Location = new System.Drawing.Point(32, 231);
			this.label3.Name = "label3";
			this.label3.Size = new System.Drawing.Size(150, 23);
			this.label3.TabIndex = 38;
			this.label3.Text = "Адрес доставки";
			// 
			// textBox2
			// 
			this.textBox2.Font = new System.Drawing.Font("Times New Roman", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.textBox2.Location = new System.Drawing.Point(194, 219);
			this.textBox2.Multiline = true;
			this.textBox2.Name = "textBox2";
			this.textBox2.Size = new System.Drawing.Size(350, 98);
			this.textBox2.TabIndex = 39;
			// 
			// comboBox3
			// 
			this.comboBox3.Font = new System.Drawing.Font("Times New Roman", 15.75F);
			this.comboBox3.FormattingEnabled = true;
			this.comboBox3.Location = new System.Drawing.Point(198, 419);
			this.comboBox3.Name = "comboBox3";
			this.comboBox3.Size = new System.Drawing.Size(348, 31);
			this.comboBox3.TabIndex = 41;
			// 
			// label4
			// 
			this.label4.AutoSize = true;
			this.label4.Font = new System.Drawing.Font("Times New Roman", 15.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.label4.Location = new System.Drawing.Point(120, 422);
			this.label4.Name = "label4";
			this.label4.Size = new System.Drawing.Size(62, 23);
			this.label4.TabIndex = 40;
			this.label4.Text = "Город";
			// 
			// label9
			// 
			this.label9.AutoSize = true;
			this.label9.Font = new System.Drawing.Font("Times New Roman", 15.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.label9.Location = new System.Drawing.Point(53, 472);
			this.label9.Name = "label9";
			this.label9.Size = new System.Drawing.Size(134, 23);
			this.label9.TabIndex = 42;
			this.label9.Text = "Пункт выдачи";
			// 
			// comboBox4
			// 
			this.comboBox4.Font = new System.Drawing.Font("Times New Roman", 15.75F);
			this.comboBox4.FormattingEnabled = true;
			this.comboBox4.Location = new System.Drawing.Point(198, 469);
			this.comboBox4.Name = "comboBox4";
			this.comboBox4.Size = new System.Drawing.Size(348, 31);
			this.comboBox4.TabIndex = 43;
			// 
			// numericUpDown1
			// 
			this.numericUpDown1.Font = new System.Drawing.Font("Times New Roman", 15.75F);
			this.numericUpDown1.Location = new System.Drawing.Point(196, 373);
			this.numericUpDown1.Name = "numericUpDown1";
			this.numericUpDown1.Size = new System.Drawing.Size(350, 32);
			this.numericUpDown1.TabIndex = 44;
			// 
			// checkBoxPaid
			// 
			this.checkBoxPaid.AutoSize = true;
			this.checkBoxPaid.Font = new System.Drawing.Font("Times New Roman", 15.75F);
			this.checkBoxPaid.Location = new System.Drawing.Point(556, 375);
			this.checkBoxPaid.Name = "checkBoxPaid";
			this.checkBoxPaid.Size = new System.Drawing.Size(101, 27);
			this.checkBoxPaid.TabIndex = 45;
			this.checkBoxPaid.Text = "Оплачен";
			this.checkBoxPaid.UseVisualStyleBackColor = true;
			// 
			// OrderForm
			// 
			this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
			this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			this.ClientSize = new System.Drawing.Size(1160, 686);
			this.Controls.Add(this.checkBoxPaid);
			this.Controls.Add(this.numericUpDown1);
			this.Controls.Add(this.comboBox4);
			this.Controls.Add(this.label9);
			this.Controls.Add(this.comboBox3);
			this.Controls.Add(this.label4);
			this.Controls.Add(this.textBox2);
			this.Controls.Add(this.label3);
			this.Controls.Add(this.comboBox2);
			this.Controls.Add(this.label8);
			this.Controls.Add(this.textBox5);
			this.Controls.Add(this.label7);
			this.Controls.Add(this.comboBox1);
			this.Controls.Add(this.textBox1);
			this.Controls.Add(this.label6);
			this.Controls.Add(this.label5);
			this.Controls.Add(this.label2);
			this.Controls.Add(this.labelComments);
			this.Controls.Add(this.flowLayoutProducts);
			this.Controls.Add(this.label1);
			this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
			this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
			this.Name = "OrderForm";
			this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.OrderForm_FormClosing);
			this.Load += new System.EventHandler(this.OrderForm_Load);
			((System.ComponentModel.ISupportInitialize)(this.numericUpDown1)).EndInit();
			this.ResumeLayout(false);
			this.PerformLayout();

		}

		#endregion

		private System.Windows.Forms.Label label1;
		private System.Windows.Forms.FlowLayoutPanel flowLayoutProducts;
		private System.Windows.Forms.Label labelComments;
		private System.Windows.Forms.ComboBox comboBox1;
		private System.Windows.Forms.TextBox textBox1;
		private System.Windows.Forms.Label label6;
		private System.Windows.Forms.Label label5;
		private System.Windows.Forms.Label label2;
		private System.Windows.Forms.TextBox textBox5;
		private System.Windows.Forms.Label label7;
		private System.Windows.Forms.ComboBox comboBox2;
		private System.Windows.Forms.Label label8;
		private System.Windows.Forms.Label label3;
		private System.Windows.Forms.TextBox textBox2;
		private System.Windows.Forms.ComboBox comboBox3;
		private System.Windows.Forms.Label label4;
		private System.Windows.Forms.Label label9;
		private System.Windows.Forms.ComboBox comboBox4;
		private System.Windows.Forms.NumericUpDown numericUpDown1;
		private System.Windows.Forms.CheckBox checkBoxPaid;
	}
}