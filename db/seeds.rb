require "date"
# create admin
# admin = User.new(email: 'admin@hendb.com', is_admin: true)
# admin.encrypt_password('password')
# admin.save!

s1 = Date.parse("2017/02/03")
s2 = Date.parse("2017/12/31")

(1..10).each do |a|
  univ = Univ.new(
    name: "Univ#{a}",
    dept: "Dept#{a}",
    pref: "Pref#{a}",
    deviation_value: 60 - a,
    exam_date: Random.rand(s1 .. s2),
    result_date: Random.rand(s1 .. s2),
    affirmation_date: Random.rand(s1 .. s2),
    document_url: 'https://github.com',
    remark: "備考です")
  sbj = (1..9).to_a.shuffle!
  3.times do
    univ.exams.build(subject: sbj.pop)
  end
  univ.save!
end