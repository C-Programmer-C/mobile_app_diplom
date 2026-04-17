namespace ManagementSystem
{
	partial class ProductsForm
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
			System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(ProductsForm));
			this.buttonBack = new System.Windows.Forms.Button();
			this.flowLayoutProducts = new System.Windows.Forms.FlowLayoutPanel();
			this.label1 = new System.Windows.Forms.Label();
			this.button1 = new System.Windows.Forms.Button();
			this.SuspendLayout();
			// 
			// buttonBack
			// 
			this.buttonBack.Font = new System.Drawing.Font("Times New Roman", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.buttonBack.Location = new System.Drawing.Point(12, 63);
			this.buttonBack.Name = "buttonBack";
			this.buttonBack.Size = new System.Drawing.Size(95, 33);
			this.buttonBack.TabIndex = 4;
			this.buttonBack.Text = "Назад";
			this.buttonBack.UseVisualStyleBackColor = true;
			this.buttonBack.Click += new System.EventHandler(this.buttonBack_Click);
			// 
			// flowLayoutProducts
			// 
			this.flowLayoutProducts.AutoScroll = true;
			this.flowLayoutProducts.BackColor = System.Drawing.SystemColors.ControlLight;
			this.flowLayoutProducts.Location = new System.Drawing.Point(12, 102);
			this.flowLayoutProducts.Name = "flowLayoutProducts";
			this.flowLayoutProducts.Padding = new System.Windows.Forms.Padding(8);
			this.flowLayoutProducts.Size = new System.Drawing.Size(776, 378);
			this.flowLayoutProducts.TabIndex = 5;
			this.flowLayoutProducts.WrapContents = false;
			// 
			// label1
			// 
			this.label1.AutoSize = true;
			this.label1.Font = new System.Drawing.Font("Microsoft YaHei UI", 20.25F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
			this.label1.Location = new System.Drawing.Point(347, 9);
			this.label1.Name = "label1";
			this.label1.Size = new System.Drawing.Size(124, 36);
			this.label1.TabIndex = 3;
			this.label1.Text = "Товары";
			// 
			// button1
			// 
			this.button1.Font = new System.Drawing.Font("Times New Roman", 12F);
			this.button1.Location = new System.Drawing.Point(683, 12);
			this.button1.Name = "button1";
			this.button1.Size = new System.Drawing.Size(105, 56);
			this.button1.TabIndex = 6;
			this.button1.Text = "Создать товар";
			this.button1.UseVisualStyleBackColor = true;
			// 
			// ProductsForm
			// 
			this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
			this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			this.ClientSize = new System.Drawing.Size(800, 492);
			this.Controls.Add(this.button1);
			this.Controls.Add(this.flowLayoutProducts);
			this.Controls.Add(this.buttonBack);
			this.Controls.Add(this.label1);
			this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedSingle;
			this.Icon = ((System.Drawing.Icon)(resources.GetObject("$this.Icon")));
			this.Name = "ProductsForm";
			this.FormClosing += new System.Windows.Forms.FormClosingEventHandler(this.ProductsForm_FormClosing);
			this.Load += new System.EventHandler(this.ProductsForm_Load);
			this.ResumeLayout(false);
			this.PerformLayout();

		}

		#endregion
		private System.Windows.Forms.Button buttonBack;
		private System.Windows.Forms.FlowLayoutPanel flowLayoutProducts;
		private System.Windows.Forms.Label label1;
		private System.Windows.Forms.Button button1;
	}
}